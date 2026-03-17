const crypto = require("crypto");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { onRequest, setGlobalOptions } = require("firebase-functions/v2/https");

admin.initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const db = admin.firestore();

function withCors(handler) {
  return async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Authorization, Content-Type, x-internal-secret");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      await handler(req, res);
    } catch (error) {
      logger.error("Unhandled function error", error);
      res.status(500).json({
        ok: false,
        error: error.message || "internal-error",
      });
    }
  };
}

function sanitizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function sanitizePhone(phone) {
  return String(phone || "").replace(/\D/g, "");
}

function sanitizeUrl(url) {
  return String(url || "").trim().replace(/\/+$/, "");
}

function membershipDocId(tenantId, userId) {
  return `${tenantId}_${userId}`;
}

function nowTs() {
  return admin.firestore.FieldValue.serverTimestamp();
}

function generateTemporaryPassword() {
  return crypto.randomBytes(9).toString("base64url");
}

function jsonBody(req) {
  if (req.body && typeof req.body === "object") {
    return req.body;
  }

  if (typeof req.body === "string" && req.body.trim()) {
    return JSON.parse(req.body);
  }

  return {};
}

async function verifyAuth(req) {
  const authHeader = req.headers.authorization || "";
  const match = authHeader.match(/^Bearer (.+)$/i);

  if (!match) {
    throw new Error("missing-auth-token");
  }

  return admin.auth().verifyIdToken(match[1]);
}

async function getUserProfile(uid) {
  const userDoc = await db.collection("users").doc(uid).get();
  return userDoc.exists ? userDoc.data() : null;
}

async function isSuperAdmin(uid) {
  const user = await getUserProfile(uid);
  return user?.platform_role === "superAdmin";
}

async function getMembership(tenantId, userId) {
  const doc = await db.collection("memberships").doc(membershipDocId(tenantId, userId)).get();
  return doc.exists ? { id: doc.id, ...doc.data() } : null;
}

async function assertCanManageTenant(tenantId, uid) {
  if (await isSuperAdmin(uid)) {
    return;
  }

  const membership = await getMembership(tenantId, uid);
  if (!membership || membership.is_active !== true) {
    throw new Error("tenant-access-denied");
  }

  if (!["tenantAdmin", "superAdmin"].includes(membership.role)) {
    throw new Error("tenant-management-denied");
  }
}

async function assertCanAccessTenant(tenantId, uid) {
  if (await isSuperAdmin(uid)) {
    return;
  }

  const membership = await getMembership(tenantId, uid);
  if (!membership || membership.is_active !== true) {
    throw new Error("tenant-access-denied");
  }
}

function buildTenantData(payload) {
  const now = new Date();
  const durationDays = payload.plan === "quarterly" ? 90 : payload.plan === "monthly" ? 30 : 15;
  const expirationDate = admin.firestore.Timestamp.fromDate(
    new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000),
  );

  const tenantData = {
    name: String(payload.name || "").trim(),
    contact_email: sanitizeEmail(payload.email),
    contact_phone: sanitizePhone(payload.phone),
    plan: payload.plan || "trial",
    plan_tier: payload.planTier || "standard",
    is_active: payload.isActive !== false,
    is_expired: false,
    expiration_date: expirationDate,
    updated_at: nowTs(),
  };

  if (tenantData.plan === "trial") {
    tenantData.trial_end_date = expirationDate;
  }

  return tenantData;
}

async function getOrCreateAuthUser({ email, name }) {
  const normalizedEmail = sanitizeEmail(email);
  const displayName = String(name || "").trim();
  const temporaryPassword = process.env.DEFAULT_INVITE_PASSWORD || generateTemporaryPassword();

  try {
    const existing = await admin.auth().getUserByEmail(normalizedEmail);
    return {
      uid: existing.uid,
      isNewUser: false,
      temporaryPassword: null,
    };
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }
  }

  const created = await admin.auth().createUser({
    email: normalizedEmail,
    password: temporaryPassword,
    displayName,
  });

  return {
    uid: created.uid,
    isNewUser: true,
    temporaryPassword,
  };
}

async function upsertUserDoc({ uid, email, name, platformRole }) {
  const payload = {
    email: sanitizeEmail(email),
    name: String(name || "").trim(),
    updated_at: nowTs(),
  };

  if (platformRole) {
    payload.platform_role = platformRole;
  }

  await db.collection("users").doc(uid).set(
    {
      ...payload,
      created_at: nowTs(),
    },
    { merge: true },
  );
}

async function upsertMembership({
  tenantId,
  userId,
  role,
  userName,
  userEmail,
  addedBy,
}) {
  const ref = db.collection("memberships").doc(membershipDocId(tenantId, userId));
  const existing = await ref.get();

  await ref.set(
    {
      user_id: userId,
      tenant_id: tenantId,
      role,
      is_active: true,
      user_name: userName,
      user_email: sanitizeEmail(userEmail),
      added_by: addedBy,
      created_at: existing.exists ? existing.data().created_at || nowTs() : nowTs(),
      updated_at: nowTs(),
      removed_at: null,
      removed_by: null,
    },
    { merge: true },
  );
}

function normalizeSalePayload(body) {
  const sale = body.sale && typeof body.sale === "object" ? body.sale : body;
  const customer = sale.customer && typeof sale.customer === "object" ? sale.customer : {};
  const rawItems = Array.isArray(sale.items) ? sale.items : [];

  const items = rawItems
    .map((item) => {
      const quantity = Number(item.quantity || 1);
      const unitPrice = Number(item.unit_price ?? item.unitPrice ?? item.price ?? 0);
      const subtotal = Number(item.subtotal ?? unitPrice * quantity);

      return {
        product_id: String(item.product_id ?? item.productId ?? item.sku ?? "").trim(),
        product_name: String(item.product_name ?? item.productName ?? item.name ?? "").trim(),
        quantity,
        unit_price: unitPrice,
        subtotal,
      };
    })
    .filter((item) => item.product_id && item.product_name && item.quantity > 0);

  const total = Number(sale.total ?? sale.total_value ?? items.reduce((sum, item) => sum + item.subtotal, 0));
  const status = String(sale.status || "pending");
  const source = String(sale.source || "whatsapp_automation");

  return {
    externalId: String(
      sale.external_id ||
        sale.externalId ||
        sale.sale_id ||
        sale.saleId ||
        sale.order_id ||
        "",
    ).trim(),
    customer: {
      id: String(sale.customer_id || sale.customerId || customer.id || "").trim(),
      name: String(sale.customer_name || sale.customerName || customer.name || "").trim(),
      whatsapp: sanitizePhone(
        sale.customer_whatsapp || sale.customerWhatsapp || customer.whatsapp || customer.phone || "",
      ),
      email: sanitizeEmail(sale.customer_email || sale.customerEmail || customer.email || ""),
      address: String(sale.customer_address || sale.customerAddress || customer.address || "").trim(),
    },
    items,
    total,
    status,
    source,
    notes: sale.notes ? String(sale.notes).trim() : null,
    conversationId: sale.conversation_id || sale.conversationId || null,
    decrementStock: sale.decrement_stock === true || sale.reserve_stock === true,
  };
}

exports.createTenantWithAdmin = onRequest(
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const auth = await verifyAuth(req);
    if (!(await isSuperAdmin(auth.uid))) {
      res.status(403).json({ ok: false, error: "super-admin-required" });
      return;
    }

    const body = jsonBody(req);
    const tenantData = buildTenantData(body);

    if (!tenantData.name || !tenantData.contact_email) {
      res.status(400).json({ ok: false, error: "invalid-tenant-payload" });
      return;
    }

    const tenantRef = db.collection("tenants").doc();
    const user = await getOrCreateAuthUser({
      email: tenantData.contact_email,
      name: tenantData.name,
    });

    await upsertUserDoc({
      uid: user.uid,
      email: tenantData.contact_email,
      name: tenantData.name,
    });

    const batch = db.batch();
    batch.set(
      tenantRef,
      {
        ...tenantData,
        created_at: nowTs(),
      },
      { merge: true },
    );

    batch.set(
      db.collection("memberships").doc(membershipDocId(tenantRef.id, user.uid)),
      {
        user_id: user.uid,
        tenant_id: tenantRef.id,
        role: "tenantAdmin",
        is_active: true,
        user_name: tenantData.name,
        user_email: tenantData.contact_email,
        added_by: auth.uid,
        created_at: nowTs(),
        updated_at: nowTs(),
      },
      { merge: true },
    );

    await batch.commit();

    res.status(200).json({
      ok: true,
      tenantId: tenantRef.id,
      adminUserId: user.uid,
      isNewUser: user.isNewUser,
      temporaryPassword: user.temporaryPassword,
    });
  }),
);

exports.provisionTenantMember = onRequest(
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const auth = await verifyAuth(req);
    const body = jsonBody(req);
    const tenantId = String(body.tenantId || "").trim();
    const role = String(body.role || "user").trim();
    const name = String(body.name || "").trim();
    const email = sanitizeEmail(body.email);

    if (!tenantId || !name || !email) {
      res.status(400).json({ ok: false, error: "invalid-member-payload" });
      return;
    }

    if (!["tenantAdmin", "user"].includes(role)) {
      res.status(400).json({ ok: false, error: "invalid-member-role" });
      return;
    }

    await assertCanManageTenant(tenantId, auth.uid);

    const user = await getOrCreateAuthUser({ email, name });
    await upsertUserDoc({ uid: user.uid, email, name });

    const membershipRef = db.collection("memberships").doc(membershipDocId(tenantId, user.uid));
    const existing = await membershipRef.get();
    if (existing.exists && existing.data().is_active === true) {
      res.status(409).json({ ok: false, error: "member-already-active" });
      return;
    }

    await upsertMembership({
      tenantId,
      userId: user.uid,
      role,
      userName: name,
      userEmail: email,
      addedBy: auth.uid,
    });

    res.status(200).json({
      ok: true,
      userId: user.uid,
      isNewUser: user.isNewUser,
      temporaryPassword: user.temporaryPassword,
    });
  }),
);

exports.testEvolutionConnection = onRequest(
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const auth = await verifyAuth(req);
    const body = jsonBody(req);
    const tenantId = String(body.tenantId || "").trim();
    const evolutionApiUrl = sanitizeUrl(body.evolutionApiUrl);
    const apiKey = String(body.apiKey || "").trim();
    const instanceName = String(body.instanceName || "").trim();

    if (!tenantId || !evolutionApiUrl || !apiKey || !instanceName) {
      res.status(400).json({ ok: false, error: "invalid-whatsapp-config-payload" });
      return;
    }

    await assertCanManageTenant(tenantId, auth.uid);

    const url = `${evolutionApiUrl}/instance/${instanceName}/status`;
    const response = await fetch(url, {
      method: "GET",
      headers: {
        apikey: apiKey,
      },
    });

    const rawText = await response.text();
    let data = null;

    if (rawText) {
      try {
        data = JSON.parse(rawText);
      } catch (error) {
        logger.warn("Evolution status returned non-JSON payload", { url, rawText });
      }
    }

    if (!response.ok) {
      res.status(response.status).json({
        ok: false,
        success: false,
        error: "evolution-connection-failed",
        message: `Erro HTTP ${response.status}`,
        statusCode: response.status,
        providerResponse: data,
      });
      return;
    }

    const state = data?.instance?.state || data?.state || "unknown";
    res.status(200).json({
      ok: true,
      success: true,
      message: `WhatsApp conectado: ${state}`,
      state,
      statusCode: response.status,
      providerResponse: data,
    });
  }),
);

exports.receiveN8nSale = onRequest(
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const tenantId = String(req.query.tenantId || "").trim();
    const token = String(req.query.token || "").trim();
    if (!tenantId || !token) {
      res.status(400).json({ ok: false, error: "missing-tenant-or-token" });
      return;
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const tenantDoc = await tenantRef.get();
    if (!tenantDoc.exists) {
      res.status(404).json({ ok: false, error: "tenant-not-found" });
      return;
    }

    if ((tenantDoc.data().webhook_token || "") !== token) {
      res.status(403).json({ ok: false, error: "invalid-webhook-token" });
      return;
    }

    const payload = normalizeSalePayload(jsonBody(req));
    if (!payload.customer.whatsapp || payload.items.length === 0 || payload.total <= 0) {
      res.status(400).json({ ok: false, error: "invalid-sale-payload" });
      return;
    }

    const salesCol = tenantRef.collection("sales");
    const customersCol = tenantRef.collection("customers");
    const productsCol = tenantRef.collection("products");

    const result = await db.runTransaction(async (transaction) => {
      if (payload.externalId) {
        const existingSnapshot = await transaction.get(
          salesCol.where("external_id", "==", payload.externalId).limit(1),
        );
        if (!existingSnapshot.empty) {
          const existingDoc = existingSnapshot.docs[0];
          return {
            saleId: existingDoc.id,
            customerId: existingDoc.data().customer_id,
            created: false,
          };
        }
      }

      let customerId = payload.customer.id;
      let customerDocRef;

      if (!customerId) {
        const existingCustomer = await transaction.get(
          customersCol.where("whatsapp", "==", payload.customer.whatsapp).limit(1),
        );

        if (!existingCustomer.empty) {
          customerDocRef = existingCustomer.docs[0].ref;
          customerId = customerDocRef.id;
        }
      } else {
        customerDocRef = customersCol.doc(customerId);
      }

      if (!customerDocRef) {
        customerDocRef = customersCol.doc();
        customerId = customerDocRef.id;
        transaction.set(customerDocRef, {
          name: payload.customer.name || payload.customer.whatsapp,
          whatsapp: payload.customer.whatsapp,
          email: payload.customer.email || "",
          address: payload.customer.address || "",
          notes: "",
          is_active: true,
          agent_off: false,
          purchase_count: 0,
          total_spent: 0,
          created_at: nowTs(),
          updated_at: nowTs(),
        });
      } else {
        transaction.set(
          customerDocRef,
          {
            name: payload.customer.name || payload.customer.whatsapp,
            whatsapp: payload.customer.whatsapp,
            email: payload.customer.email || "",
            address: payload.customer.address || "",
            updated_at: nowTs(),
          },
          { merge: true },
        );
      }

      const saleRef = salesCol.doc();
      const orderStatus = payload.status === "confirmed" ? "awaiting_processing" : null;

      transaction.set(saleRef, {
        external_id: payload.externalId || null,
        customer_id: customerId,
        customer_name: payload.customer.name || payload.customer.whatsapp,
        customer_whatsapp: payload.customer.whatsapp,
        items: payload.items.map((item) => ({
          product_id: item.product_id,
          product_name: item.product_name,
          quantity: item.quantity,
          unit_price: item.unit_price,
          subtotal: item.subtotal,
        })),
        item_product_ids: payload.items.map((item) => item.product_id),
        total: payload.total,
        status: payload.status,
        source: payload.source,
        order_status: orderStatus,
        notes: payload.notes,
        conversation_id: payload.conversationId,
        created_at: nowTs(),
        updated_at: nowTs(),
      });

      if (payload.decrementStock) {
        for (const item of payload.items) {
          transaction.set(
            productsCol.doc(item.product_id),
            {
              stock: admin.firestore.FieldValue.increment(-item.quantity),
              updated_at: nowTs(),
            },
            { merge: true },
          );
        }
      }

      if (payload.status === "confirmed") {
        transaction.set(
          customerDocRef,
          {
            purchase_count: admin.firestore.FieldValue.increment(1),
            total_spent: admin.firestore.FieldValue.increment(payload.total),
            last_purchase_at: nowTs(),
            updated_at: nowTs(),
          },
          { merge: true },
        );
      }

      return {
        saleId: saleRef.id,
        customerId,
        created: true,
      };
    });

    res.status(200).json({
      ok: true,
      ...result,
    });
  }),
);

exports.createPixCheckout = onRequest(
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const auth = await verifyAuth(req);
    const body = jsonBody(req);
    const tenantId = String(body.tenantId || "").trim();
    const plan = String(body.plan || "").trim();
    const planTier = String(body.planTier || "standard").trim();
    const amount = Number(body.amount || 0);
    const expirationDays = Number(body.expirationDays || 30);

    if (!tenantId || !plan || amount <= 0) {
      res.status(400).json({ ok: false, error: "invalid-payment-payload" });
      return;
    }

    await assertCanManageTenant(tenantId, auth.uid);

    const paymentRef = db.collection(`tenants/${tenantId}/payments`).doc();
    const expiration = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + expirationDays * 24 * 60 * 60 * 1000),
    );

    await paymentRef.set({
      plan,
      plan_tier: planTier,
      amount,
      status: "pending",
      created_at: nowTs(),
      plan_expiration_date: expiration,
      provider_status: "awaiting_provider_configuration",
    });

    const orchestratorUrl = process.env.PAYMENT_ORCHESTRATOR_URL || "";
    if (!orchestratorUrl) {
      res.status(501).json({
        ok: false,
        error: "payment-provider-unconfigured",
        paymentId: paymentRef.id,
      });
      return;
    }

    const orchestratorResponse = await fetch(orchestratorUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-internal-secret": process.env.PAYMENT_ORCHESTRATOR_SECRET || "",
      },
      body: JSON.stringify({
        tenantId,
        paymentId: paymentRef.id,
        plan,
        planTier,
        amount,
        expirationDays,
      }),
    });

    if (!orchestratorResponse.ok) {
      const errorText = await orchestratorResponse.text();
      logger.error("Payment orchestrator error", errorText);
      res.status(502).json({
        ok: false,
        error: "payment-orchestrator-failed",
        paymentId: paymentRef.id,
      });
      return;
    }

    const checkout = await orchestratorResponse.json();
    await paymentRef.set(
      {
        transaction_id: checkout.transactionId || null,
        pix_code: checkout.pixCode || null,
        qr_code_base64: checkout.qrCodeBase64 || null,
        provider_status: checkout.status || "checkout_created",
        updated_at: nowTs(),
      },
      { merge: true },
    );

    res.status(200).json({
      ok: true,
      paymentId: paymentRef.id,
      pixCode: checkout.pixCode || null,
      qrCodeBase64: checkout.qrCodeBase64 || null,
      transactionId: checkout.transactionId || null,
    });
  }),
);

exports.paymentWebhook = onRequest(
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const expectedSecret = process.env.PAYMENT_WEBHOOK_SECRET || "";
    if (!expectedSecret || req.headers["x-internal-secret"] !== expectedSecret) {
      res.status(403).json({ ok: false, error: "invalid-internal-secret" });
      return;
    }

    const body = jsonBody(req);
    const tenantId = String(body.tenantId || "").trim();
    const paymentId = String(body.paymentId || "").trim();
    const status = String(body.status || "").trim();

    if (!tenantId || !paymentId || !status) {
      res.status(400).json({ ok: false, error: "invalid-payment-webhook-payload" });
      return;
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const paymentRef = tenantRef.collection("payments").doc(paymentId);

    const paymentData = {
      status,
      transaction_id: body.transactionId || null,
      pix_code: body.pixCode || null,
      qr_code_base64: body.qrCodeBase64 || null,
      updated_at: nowTs(),
    };

    if (status === "paid") {
      paymentData.paid_at = nowTs();
    }

    const batch = db.batch();
    batch.set(paymentRef, paymentData, { merge: true });

    if (status === "paid") {
      const expirationDate = body.planExpirationDate
        ? admin.firestore.Timestamp.fromDate(new Date(body.planExpirationDate))
        : admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          );

      batch.set(
        tenantRef,
        {
          plan: body.plan || "monthly",
          plan_tier: body.planTier || "standard",
          last_payment_id: paymentId,
          next_payment_date: expirationDate,
          expiration_date: expirationDate,
          is_expired: false,
          updated_at: nowTs(),
        },
        { merge: true },
      );
    }

    await batch.commit();

    res.status(200).json({ ok: true });
  }),
);

exports.syncMembershipAccessIndex = onRequest(
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const auth = await verifyAuth(req);
    if (!(await isSuperAdmin(auth.uid))) {
      res.status(403).json({ ok: false, error: "super-admin-required" });
      return;
    }

    const memberships = await db.collection("memberships").get();
    let migrated = 0;

    for (const doc of memberships.docs) {
      const data = doc.data();
      if (!data.tenant_id || !data.user_id) {
        continue;
      }

      const deterministicId = membershipDocId(data.tenant_id, data.user_id);
      const targetRef = db.collection("memberships").doc(deterministicId);

      await targetRef.set(
        {
          ...data,
          updated_at: nowTs(),
        },
        { merge: true },
      );

      if (doc.id !== deterministicId) {
        await doc.ref.delete();
      }

      if (data.role === "superAdmin") {
        await db.collection("users").doc(data.user_id).set(
          {
            platform_role: "superAdmin",
            updated_at: nowTs(),
          },
          { merge: true },
        );
      }

      migrated += 1;
    }

    res.status(200).json({
      ok: true,
      migrated,
    });
  }),
);
