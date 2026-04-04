const crypto = require("crypto");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const { defineSecret } = require("firebase-functions/params");

admin.initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const db = admin.firestore();
const EVOLUTION_API_URL = defineSecret("EVOLUTION_API_URL");
const EVOLUTION_API_KEY = defineSecret("EVOLUTION_API_KEY");

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

function slugify(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function normalizeBrazilianPhone(phone) {
  const digits = sanitizePhone(phone);
  if (!digits) return "";
  return digits.length <= 11 ? `55${digits}` : digits;
}

function normalizeSaleStatus(status) {
  const value = String(status || "").trim();
  return ["pending", "payment_sent", "confirmed", "cancelled"].includes(value)
    ? value
    : "pending";
}

function normalizeSaleSource(source) {
  const value = String(source || "").trim();
  return ["manual", "whatsapp_automation"].includes(value)
    ? value
    : "whatsapp_automation";
}

async function parseJsonResponse(response) {
  const rawText = await response.text();
  if (!rawText) {
    return { rawText, data: null };
  }

  try {
    return { rawText, data: JSON.parse(rawText) };
  } catch (error) {
    return { rawText, data: null };
  }
}

async function sendEvolutionTextMessage({
  evolutionApiUrl,
  apiKey,
  instanceName,
  phone,
  message,
}) {
  const endpoint = `${sanitizeUrl(evolutionApiUrl)}/message/sendText/${instanceName}`;
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: apiKey,
    },
    body: JSON.stringify({
      number: normalizeBrazilianPhone(phone),
      text: message,
    }),
  });

  const { rawText, data } = await parseJsonResponse(response);
  if (!response.ok) {
    throw new Error(
      `evolution-send-failed:${response.status}:${rawText || JSON.stringify(data || {})}`,
    );
  }

  return data;
}

function getManagedEvolutionConfig() {
  return {
    evolutionApiUrl: sanitizeUrl(EVOLUTION_API_URL.value()),
    apiKey: String(EVOLUTION_API_KEY.value() || "").trim(),
  };
}

function hasManagedEvolutionSecrets() {
  const { evolutionApiUrl, apiKey } = getManagedEvolutionConfig();
  return Boolean(evolutionApiUrl && apiKey);
}

function normalizeManagedInstanceName(tenantId, tenantName) {
  const tenantSlug = slugify(tenantName) || "tenant";
  const tenantSuffix = slugify(tenantId).slice(0, 12) || crypto.randomUUID().slice(0, 12);
  return `saas-manu-${tenantSlug}-${tenantSuffix}`.slice(0, 60);
}

function resolveTenantEvolutionConfig(tenantData = {}) {
  const manualConfig = {
    evolutionApiUrl: sanitizeUrl(tenantData.evolution_api_url),
    apiKey: String(tenantData.evolution_api_key || "").trim(),
    instanceName: String(tenantData.evolution_instance_name || "").trim(),
    source: "manual",
  };

  if (manualConfig.evolutionApiUrl && manualConfig.apiKey && manualConfig.instanceName) {
    return manualConfig;
  }

  const managedInstanceName =
    String(tenantData.whatsapp_instance_id || tenantData.evolution_instance_name || "").trim();
  const provider = String(tenantData.whatsapp_provider || "").trim().toLowerCase();
  const managedSecrets = getManagedEvolutionConfig();

  if (managedInstanceName && managedSecrets.evolutionApiUrl && managedSecrets.apiKey) {
    return {
      evolutionApiUrl: managedSecrets.evolutionApiUrl,
      apiKey: managedSecrets.apiKey,
      instanceName: managedInstanceName,
      source: provider === "evolution" ? "managed" : "managed-fallback",
    };
  }

  return null;
}

async function evolutionRequest({
  evolutionApiUrl,
  apiKey,
  method = "GET",
  path,
  body,
}) {
  const response = await fetch(`${sanitizeUrl(evolutionApiUrl)}${path}`, {
    method,
    headers: {
      apikey: apiKey,
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  const { rawText, data } = await parseJsonResponse(response);
  return {
    ok: response.ok,
    status: response.status,
    rawText,
    data,
  };
}

function extractEvolutionState(payload) {
  const state = String(
    payload?.instance?.state ||
      payload?.state ||
      payload?.connectionStatus ||
      payload?.status ||
      "",
  )
    .trim()
    .toLowerCase();

  if (!state) return "unconfigured";
  if (["open", "connected"].includes(state)) return "connected";
  if (["connecting"].includes(state)) return "connecting";
  if (["close", "closed", "disconnected"].includes(state)) return "disconnected";
  if (["qrcode", "qr", "awaiting_qr_scan"].includes(state)) return "awaiting_qr_scan";
  return state;
}

function extractEvolutionConnectedNumber(payload) {
  return sanitizePhone(
    payload?.instance?.owner ||
      payload?.instance?.profileName ||
      payload?.instance?.profilePictureUrl ||
      payload?.instance?.number ||
      payload?.number ||
      payload?.owner ||
      "",
  );
}

function extractEvolutionQrCode(payload) {
  const qrValue =
    payload?.base64 ||
    payload?.qrcode ||
    payload?.qr ||
    payload?.code ||
    payload?.data?.base64 ||
    payload?.data?.qrcode ||
    payload?.data?.qr ||
    payload?.data?.code ||
    payload?.instance?.qrcode ||
    payload?.instance?.qr;

  if (!qrValue) return null;
  const normalized = String(qrValue).trim();
  if (!normalized) return null;
  return normalized.replace(/^data:image\/png;base64,/, "");
}

async function createEvolutionInstance({
  evolutionApiUrl,
  apiKey,
  instanceName,
}) {
  const attempts = [
    {
      path: "/instance/create",
      body: {
        instanceName,
        integration: "WHATSAPP-BAILEYS",
        qrcode: true,
      },
    },
    {
      path: "/instance/create",
      body: {
        instanceName,
        token: crypto.randomUUID(),
        qrcode: true,
      },
    },
  ];

  let lastResponse = null;
  for (const attempt of attempts) {
    const response = await evolutionRequest({
      evolutionApiUrl,
      apiKey,
      method: "POST",
      path: attempt.path,
      body: attempt.body,
    });
    lastResponse = response;

    if (response.ok) {
      return response;
    }

    const bodyText = (response.rawText || "").toLowerCase();
    if (
      response.status === 409 ||
      bodyText.includes("already exists") ||
      bodyText.includes("instance already exists")
    ) {
      return response;
    }
  }

  return lastResponse;
}

async function getEvolutionInstanceStatus({
  evolutionApiUrl,
  apiKey,
  instanceName,
}) {
  const attempts = [
    { method: "GET", path: `/instance/${instanceName}/status` },
    { method: "GET", path: `/instance/connectionState/${instanceName}` },
  ];

  for (const attempt of attempts) {
    const response = await evolutionRequest({
      evolutionApiUrl,
      apiKey,
      method: attempt.method,
      path: attempt.path,
    });

    if (response.ok) {
      return response;
    }
  }

  return {
    ok: false,
    status: 502,
    rawText: "",
    data: null,
  };
}

async function getEvolutionInstanceQrCode({
  evolutionApiUrl,
  apiKey,
  instanceName,
}) {
  const attempts = [
    { method: "GET", path: `/instance/connect/${instanceName}` },
    { method: "GET", path: `/instance/qrcode/${instanceName}` },
  ];

  for (const attempt of attempts) {
    const response = await evolutionRequest({
      evolutionApiUrl,
      apiKey,
      method: attempt.method,
      path: attempt.path,
    });

    if (response.ok) {
      return response;
    }
  }

  return {
    ok: false,
    status: 502,
    rawText: "",
    data: null,
  };
}

async function persistManagedWhatsAppState({
  tenantId,
  tenantData = {},
  instanceName,
  status,
  connectedNumber,
  webhookUrl,
  qrCodeBase64,
}) {
  const nextStatus = String(status || "unconfigured").trim() || "unconfigured";
  const payload = {
    whatsapp_provider: "evolution",
    whatsapp_instance_id: instanceName,
    whatsapp_connection_status: nextStatus,
    evolution_instance_name: instanceName,
    updated_at: nowTs(),
  };

  if (connectedNumber) {
    payload.whatsapp_connected_number = connectedNumber;
  }

  if (webhookUrl) {
    payload.whatsapp_webhook_url = webhookUrl;
  }

  if (nextStatus === "connected") {
    payload.whatsapp_last_seen_at = nowTs();
  }

  if (qrCodeBase64) {
    payload.whatsapp_qr_expires_at = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 60 * 1000),
    );
  } else if (tenantData.whatsapp_qr_expires_at) {
    payload.whatsapp_qr_expires_at = null;
  }

  await db.collection("tenants").doc(tenantId).set(payload, { merge: true });
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
  const deterministicDoc = await db
    .collection("memberships")
    .doc(membershipDocId(tenantId, userId))
    .get();

  if (deterministicDoc.exists) {
    return { id: deterministicDoc.id, ...deterministicDoc.data() };
  }

  const legacySnapshot = await db
    .collection("memberships")
    .where("tenant_id", "==", tenantId)
    .where("user_id", "==", userId)
    .limit(1)
    .get();

  if (legacySnapshot.empty) {
    return null;
  }

  const legacyDoc = legacySnapshot.docs[0];
  const legacyData = legacyDoc.data() || {};

  // Auto-repara o indice deterministico sem depender de rodar a migracao manualmente.
  await db
    .collection("memberships")
    .doc(membershipDocId(tenantId, userId))
    .set(
      {
        ...legacyData,
        tenant_id: tenantId,
        user_id: userId,
        updated_at: nowTs(),
      },
      { merge: true },
    );

  return { id: legacyDoc.id, ...legacyData };
}

function normalizeMembershipRole(role) {
  const value = String(role || "").trim().toLowerCase();
  if (["superadmin", "super_admin"].includes(value)) return "superAdmin";
  if (["tenantadmin", "tenant_admin", "admin", "administrator"].includes(value)) {
    return "tenantAdmin";
  }
  return value || "user";
}

async function assertCanManageTenant(tenantId, uid) {
  if (await isSuperAdmin(uid)) {
    return;
  }

  const membership = await getMembership(tenantId, uid);
  if (!membership || membership.is_active !== true) {
    throw new Error("tenant-access-denied");
  }

  if (!["tenantAdmin", "superAdmin"].includes(normalizeMembershipRole(membership.role))) {
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
        product_id: String(item.product_id ?? item.productId ?? "").trim(),
        sku: String(item.sku ?? item.product_sku ?? item.productSku ?? "").trim(),
        product_name: String(item.product_name ?? item.productName ?? item.name ?? "").trim(),
        quantity,
        unit_price: unitPrice,
        subtotal,
      };
    })
    .filter((item) => (item.product_id || item.sku) && item.product_name && item.quantity > 0);

  const total = Number(sale.total ?? sale.total_value ?? items.reduce((sum, item) => sum + item.subtotal, 0));
  const status = normalizeSaleStatus(sale.status || "pending");
  const source = normalizeSaleSource(sale.source || "whatsapp_automation");

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

exports.provisionManagedWhatsApp = onRequest(
  { secrets: [EVOLUTION_API_URL, EVOLUTION_API_KEY] },
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    if (!hasManagedEvolutionSecrets()) {
      res.status(501).json({ ok: false, error: "managed-whatsapp-unconfigured" });
      return;
    }

    const auth = await verifyAuth(req);
    const body = jsonBody(req);
    const tenantId = String(body.tenantId || "").trim();
    if (!tenantId) {
      res.status(400).json({ ok: false, error: "missing-tenant-id" });
      return;
    }

    await assertCanManageTenant(tenantId, auth.uid);

    const tenantRef = db.collection("tenants").doc(tenantId);
    const tenantDoc = await tenantRef.get();
    if (!tenantDoc.exists) {
      res.status(404).json({ ok: false, error: "tenant-not-found" });
      return;
    }

    const tenantData = tenantDoc.data() || {};
    const instanceName =
      String(tenantData.whatsapp_instance_id || tenantData.evolution_instance_name || "").trim() ||
      normalizeManagedInstanceName(tenantId, tenantData.name);
    const { evolutionApiUrl, apiKey } = getManagedEvolutionConfig();

    const createResponse = await createEvolutionInstance({
      evolutionApiUrl,
      apiKey,
      instanceName,
    });
    const statusResponse = await getEvolutionInstanceStatus({
      evolutionApiUrl,
      apiKey,
      instanceName,
    });
    const qrResponse = await getEvolutionInstanceQrCode({
      evolutionApiUrl,
      apiKey,
      instanceName,
    });

    const statusPayload = statusResponse.data || createResponse.data || {};
    const connectionStatus = extractEvolutionState(statusPayload);
    const connectedNumber = extractEvolutionConnectedNumber(statusPayload);
    const qrCodeBase64 = extractEvolutionQrCode(qrResponse.data || createResponse.data);
    const webhookUrl = String(body.webhookUrl || tenantData.whatsapp_webhook_url || "").trim();

    await persistManagedWhatsAppState({
      tenantId,
      tenantData,
      instanceName,
      status: qrCodeBase64 && connectionStatus === "unconfigured"
          ? "awaiting_qr_scan"
          : connectionStatus,
      connectedNumber,
      webhookUrl,
      qrCodeBase64,
    });

    res.status(200).json({
      ok: true,
      instanceName,
      provider: "evolution",
      connectionStatus:
        qrCodeBase64 && connectionStatus === "unconfigured"
          ? "awaiting_qr_scan"
          : connectionStatus,
      connectedNumber,
      qrCodeBase64,
      createStatusCode: createResponse?.status || null,
      statusStatusCode: statusResponse?.status || null,
      qrStatusCode: qrResponse?.status || null,
      managed: true,
    });
  }),
);

exports.getManagedWhatsAppStatus = onRequest(
  { secrets: [EVOLUTION_API_URL, EVOLUTION_API_KEY] },
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    if (!hasManagedEvolutionSecrets()) {
      res.status(501).json({ ok: false, error: "managed-whatsapp-unconfigured" });
      return;
    }

    const auth = await verifyAuth(req);
    const body = jsonBody(req);
    const tenantId = String(body.tenantId || "").trim();
    const includeQrCode = body.includeQrCode === true;
    if (!tenantId) {
      res.status(400).json({ ok: false, error: "missing-tenant-id" });
      return;
    }

    await assertCanManageTenant(tenantId, auth.uid);

    const tenantRef = db.collection("tenants").doc(tenantId);
    const tenantDoc = await tenantRef.get();
    if (!tenantDoc.exists) {
      res.status(404).json({ ok: false, error: "tenant-not-found" });
      return;
    }

    const tenantData = tenantDoc.data() || {};
    const resolvedConfig = resolveTenantEvolutionConfig(tenantData);
    if (!resolvedConfig || !resolvedConfig.instanceName) {
      res.status(404).json({ ok: false, error: "managed-whatsapp-not-provisioned" });
      return;
    }

    const statusResponse = await getEvolutionInstanceStatus(resolvedConfig);
    if (!statusResponse.ok) {
      res.status(statusResponse.status || 502).json({
        ok: false,
        error: "managed-whatsapp-status-failed",
        providerResponse: statusResponse.data,
      });
      return;
    }

    const connectionStatus = extractEvolutionState(statusResponse.data);
    let qrCodeBase64 = null;

    if (includeQrCode && connectionStatus !== "connected") {
      const qrResponse = await getEvolutionInstanceQrCode(resolvedConfig);
      qrCodeBase64 = extractEvolutionQrCode(qrResponse.data);
    }

    const connectedNumber = extractEvolutionConnectedNumber(statusResponse.data);
    await persistManagedWhatsAppState({
      tenantId,
      tenantData,
      instanceName: resolvedConfig.instanceName,
      status: qrCodeBase64 && connectionStatus === "unconfigured"
          ? "awaiting_qr_scan"
          : connectionStatus,
      connectedNumber,
      webhookUrl: tenantData.whatsapp_webhook_url,
      qrCodeBase64,
    });

    res.status(200).json({
      ok: true,
      managed: true,
      provider: "evolution",
      instanceName: resolvedConfig.instanceName,
      connectionStatus:
        qrCodeBase64 && connectionStatus === "unconfigured"
          ? "awaiting_qr_scan"
          : connectionStatus,
      connectedNumber,
      qrCodeBase64,
      providerResponse: statusResponse.data,
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
      const paymentRequestedAt =
        payload.status === "payment_sent" || payload.status === "confirmed"
          ? nowTs()
          : null;
      const paymentConfirmedAt =
        payload.status === "confirmed" ? nowTs() : null;

      const quantityByProduct = new Map();
      const productsById = new Map();
      const productLookupCache = new Map();
      const resolvedItems = [];

      for (const item of payload.items) {
        const lookupKey = item.product_id ? `id:${item.product_id}` : `sku:${item.sku}`;
        let resolvedProduct = productLookupCache.get(lookupKey);

        if (!resolvedProduct) {
          let productDoc;

          if (item.product_id) {
            productDoc = await transaction.get(productsCol.doc(item.product_id));
            if (!productDoc.exists) {
              throw new Error(`product-not-found:${item.product_id}`);
            }
          } else {
            const skuSnapshot = await transaction.get(
              productsCol.where("sku", "==", item.sku).limit(1),
            );
            if (skuSnapshot.empty) {
              throw new Error(`product-not-found-by-sku:${item.sku}`);
            }
            productDoc = skuSnapshot.docs[0];
          }

          const productData = productDoc.data() || {};
          if (productData.is_active === false) {
            throw new Error(`product-inactive:${productDoc.id}`);
          }

          resolvedProduct = {
            id: productDoc.id,
            ref: productDoc.ref,
            data: productData,
          };
          productLookupCache.set(lookupKey, resolvedProduct);
          if (item.product_id && item.product_id !== productDoc.id) {
            productLookupCache.set(`id:${item.product_id}`, resolvedProduct);
          }
          if (item.sku) {
            productLookupCache.set(`sku:${item.sku}`, resolvedProduct);
          }
          const productSku = String(productData.sku || "").trim();
          if (productSku) {
            productLookupCache.set(`sku:${productSku}`, resolvedProduct);
          }
        }

        quantityByProduct.set(
          resolvedProduct.id,
          (quantityByProduct.get(resolvedProduct.id) || 0) + item.quantity,
        );
        productsById.set(resolvedProduct.id, resolvedProduct);
        resolvedItems.push({
          product_id: resolvedProduct.id,
          sku: String(resolvedProduct.data.sku || item.sku || "").trim(),
          product_name: String(resolvedProduct.data.name || item.product_name || "").trim(),
          quantity: item.quantity,
          unit_price: item.unit_price,
          subtotal: item.subtotal,
        });
      }

      for (const [productId, requestedQuantity] of quantityByProduct.entries()) {
        const product = productsById.get(productId);
        const currentStock = Number(product?.data?.stock || 0);
        if (payload.decrementStock && currentStock < requestedQuantity) {
          throw new Error(`insufficient-stock:${productId}`);
        }
      }

      const normalizedItems = resolvedItems.map((item) => ({
        product_id: item.product_id,
        sku: item.sku,
        product_name: item.product_name,
        quantity: item.quantity,
        unit_price: item.unit_price,
        subtotal: item.subtotal,
      }));

      transaction.set(saleRef, {
        external_id: payload.externalId || null,
        customer_id: customerId,
        customer_name: payload.customer.name || payload.customer.whatsapp,
        customer_whatsapp: payload.customer.whatsapp,
        customer_email: payload.customer.email || "",
        customer_address: payload.customer.address || "",
        items: normalizedItems,
        item_product_ids: normalizedItems.map((item) => item.product_id),
        item_count: normalizedItems.reduce((sum, item) => sum + item.quantity, 0),
        total: payload.total,
        status: payload.status,
        source: payload.source,
        order_status: orderStatus,
        notes: payload.notes,
        conversation_id: payload.conversationId,
        created_at: nowTs(),
        updated_at: nowTs(),
        payment_requested_at: paymentRequestedAt,
        payment_confirmed_at: paymentConfirmedAt,
      });

      if (payload.decrementStock) {
        for (const [productId, requestedQuantity] of quantityByProduct.entries()) {
          transaction.set(
            productsCol.doc(productId),
            {
              stock: admin.firestore.FieldValue.increment(-requestedQuantity),
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

exports.notifyRestockCustomers = onRequest(
  { secrets: [EVOLUTION_API_URL, EVOLUTION_API_KEY] },
  withCors(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method-not-allowed" });
      return;
    }

    const auth = await verifyAuth(req);
    const body = jsonBody(req);
    const tenantId = String(body.tenantId || "").trim();
    const productId = String(body.productId || "").trim();

    if (!tenantId || !productId) {
      res.status(400).json({ ok: false, error: "invalid-restock-payload" });
      return;
    }

    await assertCanManageTenant(tenantId, auth.uid);

    const tenantRef = db.collection("tenants").doc(tenantId);
    const productRef = tenantRef.collection("products").doc(productId);
    const alertsQuery = tenantRef
      .collection("stockAlerts")
      .where("product_id", "==", productId)
      .where("status", "==", "pending");

    const [tenantDoc, productDoc, alertsSnapshot] = await Promise.all([
      tenantRef.get(),
      productRef.get(),
      alertsQuery.get(),
    ]);

    if (!tenantDoc.exists) {
      res.status(404).json({ ok: false, error: "tenant-not-found" });
      return;
    }

    if (!productDoc.exists) {
      res.status(404).json({ ok: false, error: "product-not-found" });
      return;
    }

    const tenantData = tenantDoc.data() || {};
    const productData = productDoc.data() || {};
    const stock = Number(productData.stock || 0);

    if (stock <= 0) {
      res.status(400).json({ ok: false, error: "product-out-of-stock" });
      return;
    }

    const tenantEvolutionConfig = resolveTenantEvolutionConfig(tenantData);
    if (!tenantEvolutionConfig) {
      res.status(400).json({ ok: false, error: "whatsapp-config-missing" });
      return;
    }

    if (alertsSnapshot.empty) {
      res.status(404).json({ ok: false, error: "no-pending-alerts" });
      return;
    }

    const tenantName = String(tenantData.name || "sua loja").trim();
    const productName = String(productData.name || "produto").trim();
    const successes = [];
    const failures = [];
    const batch = db.batch();

    for (const alertDoc of alertsSnapshot.docs) {
      const alert = alertDoc.data() || {};
      const customerName = String(alert.customer_name || "cliente").trim();
      const customerPhone = String(alert.customer_whatsapp || "").trim();
      if (!customerPhone) {
        failures.push({
          alertId: alertDoc.id,
          customerName,
          reason: "missing-customer-phone",
        });
        continue;
      }

      const message =
        `Oi ${customerName}! A ${productName} voltou ao estoque na ${tenantName}. ` +
        "Se ainda quiser, me responde aqui que eu separo pra voce.";

      try {
        await sendEvolutionTextMessage({
          evolutionApiUrl: tenantEvolutionConfig.evolutionApiUrl,
          apiKey: tenantEvolutionConfig.apiKey,
          instanceName: tenantEvolutionConfig.instanceName,
          phone: customerPhone,
          message,
        });

        batch.update(alertDoc.ref, {
          status: "notified",
          notes: "Notificacao de reposicao enviada automaticamente.",
          resolved_at: nowTs(),
          updated_at: nowTs(),
        });

        successes.push({
          alertId: alertDoc.id,
          customerName,
          customerPhone,
        });
      } catch (error) {
        logger.error("Erro ao notificar cliente sobre reposicao", {
          tenantId,
          productId,
          alertId: alertDoc.id,
          error: error.message,
        });
        failures.push({
          alertId: alertDoc.id,
          customerName,
          customerPhone,
          reason: error.message,
        });
      }
    }

    if (successes.length > 0) {
      await batch.commit();
    }

    res.status(200).json({
      ok: true,
      productId,
      productName,
      notifiedCount: successes.length,
      failedCount: failures.length,
      notifiedCustomers: successes,
      failedCustomers: failures,
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
