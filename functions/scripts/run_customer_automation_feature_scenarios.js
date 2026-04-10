#!/usr/bin/env node

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const Module = require("module");

function loadFunctionsModule() {
  const filename = path.resolve(__dirname, "..", "index.js");
  let src = fs.readFileSync(filename, "utf8");
  src = src.replace(
    'const admin = require("firebase-admin");',
    'let admin = require("firebase-admin");',
  );
  src = src.replace(
    'const logger = require("firebase-functions/logger");',
    'let logger = require("firebase-functions/logger");',
  );
  src = src.replace("const db = admin.firestore();", "let db = admin.firestore();");
  src += `
module.exports.__test = {
  normalizeOrderStatus,
  shouldNotifyOrderStatus,
  buildOrderStatusNotificationMessage,
  parseDateLike,
  summarizeCartItems,
  buildCartRecoveryMessage,
  groupEligibleCartDocs,
  syncOrderStatusNotificationState,
  setDb(value) { db = value; },
  setAdmin(value) { admin = value; },
  setLogger(value) { logger = value; },
  setSendEvolutionTextMessage(fn) { sendEvolutionTextMessage = fn; },
  setResolveTenantEvolutionConfig(fn) { resolveTenantEvolutionConfig = fn; },
  setMarkCartRecoveryState(fn) { markCartRecoveryState = fn; },
  setDeleteCartDocs(fn) { deleteCartDocs = fn; }
};`;

  const loaded = new Module(filename, module);
  loaded.filename = filename;
  loaded.paths = Module._nodeModulePaths(path.dirname(filename));
  loaded._compile(src, filename);
  return loaded.exports;
}

class MockTimestamp {
  constructor(date) {
    this.date = date instanceof Date ? date : new Date(date);
  }

  toDate() {
    return this.date;
  }

  static fromDate(date) {
    return new MockTimestamp(date);
  }

  static now() {
    return new MockTimestamp(new Date(Date.now()));
  }
}

function createMockAdmin() {
  return {
    firestore: {
      Timestamp: MockTimestamp,
      FieldValue: {
        serverTimestamp() {
          return "__server_timestamp__";
        },
      },
    },
  };
}

function createLoggerStub() {
  const entries = [];
  return {
    entries,
    info(message, payload) {
      entries.push({ level: "info", message, payload });
    },
    warn(message, payload) {
      entries.push({ level: "warn", message, payload });
    },
    error(message, payload) {
      entries.push({ level: "error", message, payload });
    },
  };
}

function createDocRef(pathValue, options = {}) {
  return {
    path: pathValue,
    async set(payload, config) {
      if (typeof options.onSet === "function") {
        return options.onSet(payload, config);
      }
      return undefined;
    },
  };
}

function createDocSnapshot({ id = "", path: pathValue, data = {}, exists = true, ref }) {
  return {
    id,
    exists,
    ref: ref || createDocRef(pathValue || id),
    data() {
      return data;
    },
  };
}

function createQuerySnapshot(docs) {
  return {
    docs,
    empty: docs.length === 0,
  };
}

function createNotificationDb({ tenantData, customerData }) {
  const tenantId = "tenant-1";
  const customerId = "customer-1";
  const tenantRef = {
    id: tenantId,
    async get() {
      return createDocSnapshot({
        id: tenantId,
        path: `tenants/${tenantId}`,
        data: tenantData,
        exists: Boolean(tenantData),
      });
    },
    collection(name) {
      if (name !== "customers") {
        throw new Error(`Unexpected collection ${name}`);
      }
      return {
        doc(id) {
          return {
            id,
            async get() {
              return createDocSnapshot({
                id,
                path: `tenants/${tenantId}/customers/${customerId}`,
                data: customerData,
                exists: Boolean(customerData),
              });
            },
          };
        },
      };
    },
  };

  return {
    collection(name) {
      if (name !== "tenants") {
        throw new Error(`Unexpected root collection ${name}`);
      }
      return {
        doc(id) {
          if (id !== tenantId) {
            throw new Error(`Unexpected tenant id ${id}`);
          }
          return tenantRef;
        },
      };
    },
  };
}

function createCartDoc({
  tenantId,
  cartId,
  phone,
  customerId = "customer-1",
  customerName = "Cliente",
  items = [],
  updatedAt,
  createdAt,
  recoveryStatus = "",
  recoveryAttemptCount = 0,
  lastRecoveryAt = null,
}) {
  const docRef = createDocRef(`tenants/${tenantId}/carts/${cartId}`);
  return createDocSnapshot({
    id: cartId,
    path: docRef.path,
    ref: docRef,
    data: {
      phone,
      customer_id: customerId,
      customer_name: customerName,
      items,
      updated_at: updatedAt,
      created_at: createdAt || updatedAt,
      recovery_status: recoveryStatus,
      recovery_attempt_count: recoveryAttemptCount,
      last_recovery_at: lastRecoveryAt,
    },
  });
}

function createProcessDb({ tenants }) {
  return {
    collection(name) {
      if (name !== "tenants") {
        throw new Error(`Unexpected root collection ${name}`);
      }
      return {
        async get() {
          return createQuerySnapshot(
            tenants.map((tenant) => {
              const customerMap = new Map(
                Object.entries(tenant.customers || {}).map(([id, data]) => [id, data]),
              );
              const makeTenantSubcollection = (collectionName) => {
                if (collectionName === "customers") {
                  return {
                    doc(id) {
                      return {
                        async get() {
                          const customerData = customerMap.get(id);
                          return createDocSnapshot({
                            id,
                            path: `tenants/${tenant.id}/customers/${id}`,
                            data: customerData || {},
                            exists: Boolean(customerData),
                          });
                        },
                      };
                    },
                  };
                }

                if (collectionName === "carts") {
                  const filters = [];
                  return {
                    where(field, operator, value) {
                      filters.push({ field, operator, value });
                      return this;
                    },
                    async get() {
                      const hasRecoveryStatusFilter = filters.some(
                        (filter) =>
                          filter.field === "recovery_status" &&
                          filter.operator === "==" &&
                          filter.value === "recovery_sent",
                      );
                      return createQuerySnapshot(
                        hasRecoveryStatusFilter ? tenant.expirationDocs || [] : tenant.recoveryDocs || [],
                      );
                    },
                  };
                }

                throw new Error(`Unexpected subcollection ${collectionName}`);
              };

              return {
                id: tenant.id,
                ref: {
                  collection: makeTenantSubcollection,
                },
                data() {
                  return tenant.data || {};
                },
                collection: makeTenantSubcollection,
              };
            }),
          );
        },
      };
    },
  };
}

function withFrozenNow(isoDate, callback) {
  const originalNow = Date.now;
  Date.now = () => new Date(isoDate).getTime();
  return Promise.resolve()
    .then(callback)
    .finally(() => {
      Date.now = originalNow;
    });
}

async function runScenario(name, fn, results) {
  try {
    await fn();
    results.push({ name, status: "passed" });
    process.stdout.write(`PASS ${name}\n`);
  } catch (error) {
    results.push({ name, status: "failed", error });
    process.stdout.write(`FAIL ${name}: ${error.message}\n`);
  }
}

async function main() {
  const functionsModule = loadFunctionsModule();
  const testApi = functionsModule.__test;
  const notifyHandler = functionsModule.notifyOrderStatusChange.run;
  const abandonedHandler = functionsModule.processAbandonedCarts.run;
  const logger = createLoggerStub();
  testApi.setLogger(logger);
  testApi.setAdmin(createMockAdmin());

  const results = [];

  await runScenario("normalize order statuses and notification eligibility", async () => {
    assert.strictEqual(testApi.normalizeOrderStatus("separating"), "awaiting_processing");
    assert.strictEqual(testApi.normalizeOrderStatus("ready"), "ready_for_shipping");
    assert.strictEqual(testApi.normalizeOrderStatus("ready_for_pickup"), "ready_for_shipping");
    assert.strictEqual(testApi.shouldNotifyOrderStatus("completed"), true);
    assert.strictEqual(testApi.shouldNotifyOrderStatus("cancelled"), false);
  }, results);

  await runScenario("build order status message with personalization", async () => {
    const message = testApi.buildOrderStatusNotificationMessage({
      customerName: "Maria",
      tenantName: "Loja Teste",
      orderNumber: "12345",
      orderStatus: "shipped",
    });
    assert.match(message, /Maria/);
    assert.match(message, /Loja Teste/);
    assert.match(message, /#12345/);
    assert.match(message, /foi enviado/);
  }, results);

  await runScenario("parse date-like values from supported formats", async () => {
    const isoDate = testApi.parseDateLike("2026-04-09T12:00:00.000Z");
    const epochSeconds = testApi.parseDateLike(1712664000);
    const timestampLike = testApi.parseDateLike({ toDate: () => new Date("2026-04-09T14:00:00Z") });
    assert.strictEqual(isoDate.toISOString(), "2026-04-09T12:00:00.000Z");
    assert.strictEqual(epochSeconds.toISOString(), "2024-04-09T12:00:00.000Z");
    assert.strictEqual(timestampLike.toISOString(), "2026-04-09T14:00:00.000Z");
    assert.strictEqual(testApi.parseDateLike("not-a-date"), null);
  }, results);

  await runScenario("summarize cart items with truncation and fallback", async () => {
    assert.strictEqual(testApi.summarizeCartItems([]), "itens no carrinho");
    const summary = testApi.summarizeCartItems([
      { quantity: 2, product_name: "Pizza Calabresa" },
      { quantity: 1, product_name: "Refrigerante" },
      { quantity: 3, name: "Brownie" },
      { quantity: 1, name: "Extra" },
    ]);
    assert.strictEqual(summary, "2x Pizza Calabresa; 1x Refrigerante; 3x Brownie");
  }, results);

  await runScenario("group eligible cart docs by tenant and phone using latest context", async () => {
    const docs = [
      createCartDoc({
        tenantId: "tenant-1",
        cartId: "cart-1",
        phone: "(11) 99999-1111",
        items: [{ quantity: 1, product_name: "Burger" }],
        updatedAt: "2026-04-09T10:00:00.000Z",
        recoveryStatus: "recovery_error",
      }),
      createCartDoc({
        tenantId: "tenant-1",
        cartId: "cart-2",
        phone: "11999991111",
        items: [{ quantity: 2, product_name: "Batata" }],
        updatedAt: "2026-04-09T11:00:00.000Z",
        recoveryAttemptCount: 1,
        lastRecoveryAt: new MockTimestamp("2026-04-09T11:30:00.000Z"),
      }),
      createCartDoc({
        tenantId: "tenant-2",
        cartId: "cart-3",
        phone: "21999992222",
        items: [{ quantity: 1, product_name: "Suco" }],
        updatedAt: "2026-04-09T09:00:00.000Z",
      }),
    ];

    const groups = testApi.groupEligibleCartDocs(docs);
    assert.strictEqual(groups.length, 2);
    const tenantOne = groups.find((group) => group.tenantId === "tenant-1");
    assert.ok(tenantOne);
    assert.strictEqual(tenantOne.docs.length, 2);
    assert.strictEqual(tenantOne.items[0].product_name, "Batata");
    assert.strictEqual(tenantOne.maxRecoveryAttemptCount, 1);
    assert.strictEqual(tenantOne.recoveryStatus, "recovery_error");
    assert.strictEqual(tenantOne.latestRecoveryAt.toISOString(), "2026-04-09T11:30:00.000Z");
  }, results);

  await runScenario("notify order status change on eligible confirmed whatsapp sale", async () => {
    const sentMessages = [];
    const saleWrites = [];
    testApi.setDb(
      createNotificationDb({
        tenantData: {
          name: "Loja Teste",
          evolution_api_url: "https://evolution.local",
          evolution_api_key: "key",
          evolution_instance_name: "instance",
        },
        customerData: { name: "Maria" },
      }),
    );
    testApi.setSendEvolutionTextMessage(async (payload) => {
      sentMessages.push(payload);
    });
    testApi.setResolveTenantEvolutionConfig((tenantData) => ({
      evolutionApiUrl: tenantData.evolution_api_url,
      apiKey: tenantData.evolution_api_key,
      instanceName: tenantData.evolution_instance_name,
    }));

    const saleRef = createDocRef("tenants/tenant-1/sales/sale-1", {
      onSet(payload, config) {
        saleWrites.push({ payload, config });
      },
    });

    await notifyHandler({
      params: { tenantId: "tenant-1", saleId: "sale-1" },
      data: {
        before: { data: () => ({ order_status: "pending" }) },
        after: {
          ref: saleRef,
          data: () => ({
            order_status: "shipped",
            source: "whatsapp_automation",
            status: "confirmed",
            customer_whatsapp: "(11) 99999-0000",
            customer_id: "customer-1",
            customer_name: "Maria",
            public_order_number: "54321",
          }),
        },
      },
    });

    assert.strictEqual(sentMessages.length, 1);
    assert.strictEqual(sentMessages[0].phone, "11999990000");
    assert.match(sentMessages[0].message, /#54321/);
    assert.strictEqual(saleWrites.length, 1);
    assert.strictEqual(saleWrites[0].payload.last_notified_order_status, "shipped");
    assert.strictEqual(saleWrites[0].config.merge, true);
  }, results);

  await runScenario("skip notification when status does not change", async () => {
    let sendCount = 0;
    testApi.setDb(createNotificationDb({ tenantData: { name: "Loja" }, customerData: { name: "Joao" } }));
    testApi.setSendEvolutionTextMessage(async () => {
      sendCount += 1;
    });

    await notifyHandler({
      params: { tenantId: "tenant-1", saleId: "sale-1" },
      data: {
        before: { data: () => ({ order_status: "ready" }) },
        after: {
          ref: createDocRef("tenants/tenant-1/sales/sale-1"),
          data: () => ({
            order_status: "ready_for_pickup",
            source: "whatsapp_automation",
            status: "confirmed",
            customer_whatsapp: "11999990000",
          }),
        },
      },
    });

    assert.strictEqual(sendCount, 0);
  }, results);

  await runScenario("skip notification for unsupported sale conditions", async () => {
    const variants = [
      { source: "manual", status: "confirmed", expected: "manual source" },
      { source: "whatsapp_automation", status: "pending", expected: "sale not confirmed" },
      {
        source: "whatsapp_automation",
        status: "confirmed",
        last_notified_order_status: "completed",
        order_status: "completed",
        expected: "duplicate status",
      },
      {
        source: "whatsapp_automation",
        status: "confirmed",
        order_status: "cancelled",
        expected: "unsupported status",
      },
      {
        source: "whatsapp_automation",
        status: "confirmed",
        customer_whatsapp: "",
        expected: "missing phone",
      },
    ];

    for (const variant of variants) {
      let sendCount = 0;
      testApi.setDb(
        createNotificationDb({
          tenantData: { name: "Loja Teste" },
          customerData: { name: "Cliente" },
        }),
      );
      testApi.setSendEvolutionTextMessage(async () => {
        sendCount += 1;
      });

      await notifyHandler({
        params: { tenantId: "tenant-1", saleId: "sale-1" },
        data: {
          before: { data: () => ({ order_status: "awaiting_processing" }) },
          after: {
            ref: createDocRef("tenants/tenant-1/sales/sale-1"),
            data: () => ({
              order_status: variant.order_status || "completed",
              source: variant.source,
              status: variant.status,
              last_notified_order_status: variant.last_notified_order_status,
              customer_whatsapp: Object.prototype.hasOwnProperty.call(variant, "customer_whatsapp")
                ? variant.customer_whatsapp
                : "11999990000",
            }),
          },
        },
      });

      assert.strictEqual(sendCount, 0, `should skip for ${variant.expected}`);
    }
  }, results);

  await runScenario("skip notification when customer is under human handoff or agent off", async () => {
    for (const customerData of [
      { name: "Maria", human_handoff_pending: true },
      { name: "Maria", agent_off: true },
    ]) {
      let sendCount = 0;
      testApi.setDb(
        createNotificationDb({
          tenantData: {
            name: "Loja Teste",
            evolution_api_url: "https://evolution.local",
            evolution_api_key: "key",
            evolution_instance_name: "instance",
          },
          customerData,
        }),
      );
      testApi.setSendEvolutionTextMessage(async () => {
        sendCount += 1;
      });
      testApi.setResolveTenantEvolutionConfig(() => ({
        evolutionApiUrl: "https://evolution.local",
        apiKey: "key",
        instanceName: "instance",
      }));

      await notifyHandler({
        params: { tenantId: "tenant-1", saleId: "sale-1" },
        data: {
          before: { data: () => ({ order_status: "awaiting_processing" }) },
          after: {
            ref: createDocRef("tenants/tenant-1/sales/sale-1"),
            data: () => ({
              order_status: "completed",
              source: "whatsapp_automation",
              status: "confirmed",
              customer_id: "customer-1",
              customer_whatsapp: "11999990000",
            }),
          },
        },
      });

      assert.strictEqual(sendCount, 0);
    }
  }, results);

  await runScenario("persist notification error when sending fails", async () => {
    const saleWrites = [];
    testApi.setDb(
      createNotificationDb({
        tenantData: {
          name: "Loja Teste",
          evolution_api_url: "https://evolution.local",
          evolution_api_key: "key",
          evolution_instance_name: "instance",
        },
        customerData: { name: "Maria" },
      }),
    );
    testApi.setResolveTenantEvolutionConfig(() => ({
      evolutionApiUrl: "https://evolution.local",
      apiKey: "key",
      instanceName: "instance",
    }));
    testApi.setSendEvolutionTextMessage(async () => {
      throw new Error("network-down");
    });

    await notifyHandler({
      params: { tenantId: "tenant-1", saleId: "sale-1" },
      data: {
        before: { data: () => ({ order_status: "awaiting_processing" }) },
        after: {
          ref: createDocRef("tenants/tenant-1/sales/sale-1", {
            onSet(payload, config) {
              saleWrites.push({ payload, config });
            },
          }),
          data: () => ({
            order_status: "completed",
            source: "whatsapp_automation",
            status: "confirmed",
            customer_id: "customer-1",
            customer_whatsapp: "11999990000",
          }),
        },
      },
    });

    assert.strictEqual(saleWrites.length, 1);
    assert.strictEqual(saleWrites[0].payload.last_order_status_notification_error, "network-down");
    assert.strictEqual(
      Object.prototype.hasOwnProperty.call(saleWrites[0].payload, "last_notified_order_status"),
      false,
    );
  }, results);

  await runScenario("recover abandoned cart and mark grouped docs once", async () => {
    const sentMessages = [];
    const markedGroups = [];
    testApi.setResolveTenantEvolutionConfig(() => ({
      evolutionApiUrl: "https://evolution.local",
      apiKey: "key",
      instanceName: "instance",
    }));
    testApi.setSendEvolutionTextMessage(async (payload) => {
      sentMessages.push(payload);
    });
    testApi.setMarkCartRecoveryState(async (docs, payload) => {
      markedGroups.push({ docs, payload });
    });
    testApi.setDeleteCartDocs(async () => 0);
    testApi.setDb(
      createProcessDb({
        tenants: [
          {
            id: "tenant-1",
            data: { name: "Loja Teste" },
            customers: {
              "customer-1": {},
            },
            recoveryDocs: [
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-1",
                phone: "11999990000",
                customerId: "customer-1",
                customerName: "Maria",
                items: [{ quantity: 2, product_name: "Pizza" }],
                updatedAt: "2026-04-09T08:30:00.000Z",
              }),
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-2",
                phone: "(11) 99999-0000",
                customerId: "customer-1",
                customerName: "Maria",
                items: [{ quantity: 1, product_name: "Refrigerante" }],
                updatedAt: "2026-04-09T09:00:00.000Z",
              }),
            ],
            expirationDocs: [],
          },
        ],
      }),
    );

    await withFrozenNow("2026-04-09T12:00:00.000Z", async () => {
      await abandonedHandler();
    });

    assert.strictEqual(sentMessages.length, 1);
    assert.strictEqual(sentMessages[0].phone, "11999990000");
    assert.match(sentMessages[0].message, /Refrigerante/);
    assert.strictEqual(markedGroups.length, 1);
    assert.strictEqual(markedGroups[0].docs.length, 2);
    assert.strictEqual(markedGroups[0].payload.recovery_status, "recovery_sent");
    assert.strictEqual(markedGroups[0].payload.recovery_attempt_count, 1);
  }, results);

  await runScenario("skip cart recovery when attempts already happened or cooldown is active", async () => {
    const sentMessages = [];
    const markedGroups = [];
    testApi.setResolveTenantEvolutionConfig(() => ({
      evolutionApiUrl: "https://evolution.local",
      apiKey: "key",
      instanceName: "instance",
    }));
    testApi.setSendEvolutionTextMessage(async (payload) => {
      sentMessages.push(payload);
    });
    testApi.setMarkCartRecoveryState(async (docs, payload) => {
      markedGroups.push({ docs, payload });
    });
    testApi.setDeleteCartDocs(async () => 0);
    testApi.setDb(
      createProcessDb({
        tenants: [
          {
            id: "tenant-1",
            data: { name: "Loja Teste" },
            customers: {},
            recoveryDocs: [
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-1",
                phone: "11999990001",
                recoveryAttemptCount: 1,
                updatedAt: "2026-04-09T08:00:00.000Z",
              }),
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-2",
                phone: "11999990002",
                recoveryStatus: "recovery_error",
                lastRecoveryAt: new MockTimestamp("2026-04-09T11:00:00.000Z"),
                updatedAt: "2026-04-09T08:00:00.000Z",
              }),
            ],
            expirationDocs: [],
          },
        ],
      }),
    );

    await withFrozenNow("2026-04-09T12:00:00.000Z", async () => {
      await abandonedHandler();
    });

    assert.strictEqual(sentMessages.length, 0);
    assert.strictEqual(markedGroups.length, 0);
  }, results);

  await runScenario("skip cart recovery when customer already replied or automation is paused", async () => {
    const sentMessages = [];
    testApi.setResolveTenantEvolutionConfig(() => ({
      evolutionApiUrl: "https://evolution.local",
      apiKey: "key",
      instanceName: "instance",
    }));
    testApi.setSendEvolutionTextMessage(async (payload) => {
      sentMessages.push(payload);
    });
    testApi.setMarkCartRecoveryState(async () => {});
    testApi.setDeleteCartDocs(async () => 0);
    testApi.setDb(
      createProcessDb({
        tenants: [
          {
            id: "tenant-1",
            data: { name: "Loja Teste" },
            customers: {
              "customer-1": {
                last_inbound_message_at: "2026-04-09T11:30:00.000Z",
              },
              "customer-2": {
                human_handoff_pending: true,
              },
              "customer-3": {
                agent_off: true,
              },
            },
            recoveryDocs: [
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-1",
                phone: "11999990001",
                customerId: "customer-1",
                updatedAt: "2026-04-09T09:00:00.000Z",
              }),
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-2",
                phone: "11999990002",
                customerId: "customer-2",
                updatedAt: "2026-04-09T09:00:00.000Z",
              }),
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-3",
                phone: "11999990003",
                customerId: "customer-3",
                updatedAt: "2026-04-09T09:00:00.000Z",
              }),
            ],
            expirationDocs: [],
          },
        ],
      }),
    );

    await withFrozenNow("2026-04-09T12:00:00.000Z", async () => {
      await abandonedHandler();
    });

    assert.strictEqual(sentMessages.length, 0);
  }, results);

  await runScenario("mark recovery error when abandoned cart message fails", async () => {
    const markedGroups = [];
    testApi.setResolveTenantEvolutionConfig(() => ({
      evolutionApiUrl: "https://evolution.local",
      apiKey: "key",
      instanceName: "instance",
    }));
    testApi.setSendEvolutionTextMessage(async () => {
      throw new Error("evolution-down");
    });
    testApi.setMarkCartRecoveryState(async (docs, payload) => {
      markedGroups.push({ docs, payload });
    });
    testApi.setDeleteCartDocs(async () => 0);
    testApi.setDb(
      createProcessDb({
        tenants: [
          {
            id: "tenant-1",
            data: { name: "Loja Teste" },
            customers: {},
            recoveryDocs: [
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-1",
                phone: "11999990000",
                updatedAt: "2026-04-09T08:00:00.000Z",
              }),
            ],
            expirationDocs: [],
          },
        ],
      }),
    );

    await withFrozenNow("2026-04-09T12:00:00.000Z", async () => {
      await abandonedHandler();
    });

    assert.strictEqual(markedGroups.length, 1);
    assert.strictEqual(markedGroups[0].payload.recovery_status, "recovery_error");
    assert.strictEqual(markedGroups[0].payload.recovery_error, "evolution-down");
    assert.strictEqual(markedGroups[0].payload.recovery_attempt_count, 0);
  }, results);

  await runScenario("expire recovered carts after grace period when there is no new interaction", async () => {
    const deletedGroups = [];
    testApi.setResolveTenantEvolutionConfig(() => ({
      evolutionApiUrl: "https://evolution.local",
      apiKey: "key",
      instanceName: "instance",
    }));
    testApi.setSendEvolutionTextMessage(async () => {});
    testApi.setMarkCartRecoveryState(async () => {});
    testApi.setDeleteCartDocs(async (docs) => {
      deletedGroups.push(docs);
      return docs.length;
    });
    testApi.setDb(
      createProcessDb({
        tenants: [
          {
            id: "tenant-1",
            data: { name: "Loja Teste" },
            customers: {
              "customer-1": {},
            },
            recoveryDocs: [],
            expirationDocs: [
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-1",
                phone: "11999990000",
                customerId: "customer-1",
                updatedAt: "2026-04-08T08:00:00.000Z",
                recoveryStatus: "recovery_sent",
                lastRecoveryAt: new MockTimestamp("2026-04-08T09:00:00.000Z"),
              }),
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-2",
                phone: "11999990000",
                customerId: "customer-1",
                updatedAt: "2026-04-08T08:30:00.000Z",
                recoveryStatus: "recovery_sent",
                lastRecoveryAt: new MockTimestamp("2026-04-08T09:00:00.000Z"),
              }),
            ],
          },
        ],
      }),
    );

    await withFrozenNow("2026-04-09T12:00:00.000Z", async () => {
      await abandonedHandler();
    });

    assert.strictEqual(deletedGroups.length, 1);
    assert.strictEqual(deletedGroups[0].length, 2);
  }, results);

  await runScenario("do not expire cart when customer replied or cart changed after recovery", async () => {
    const deletedGroups = [];
    testApi.setResolveTenantEvolutionConfig(() => ({
      evolutionApiUrl: "https://evolution.local",
      apiKey: "key",
      instanceName: "instance",
    }));
    testApi.setSendEvolutionTextMessage(async () => {});
    testApi.setMarkCartRecoveryState(async () => {});
    testApi.setDeleteCartDocs(async (docs) => {
      deletedGroups.push(docs);
      return docs.length;
    });
    testApi.setDb(
      createProcessDb({
        tenants: [
          {
            id: "tenant-1",
            data: { name: "Loja Teste" },
            customers: {
              "customer-1": {
                last_inbound_message_at: "2026-04-08T10:00:00.000Z",
              },
              "customer-2": {},
            },
            recoveryDocs: [],
            expirationDocs: [
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-1",
                phone: "11999990001",
                customerId: "customer-1",
                updatedAt: "2026-04-08T08:00:00.000Z",
                recoveryStatus: "recovery_sent",
                lastRecoveryAt: new MockTimestamp("2026-04-08T09:00:00.000Z"),
              }),
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-2",
                phone: "11999990002",
                customerId: "customer-2",
                updatedAt: "2026-04-08T10:30:00.000Z",
                recoveryStatus: "recovery_sent",
                lastRecoveryAt: new MockTimestamp("2026-04-08T09:00:00.000Z"),
              }),
            ],
          },
        ],
      }),
    );

    await withFrozenNow("2026-04-09T12:00:00.000Z", async () => {
      await abandonedHandler();
    });

    assert.strictEqual(deletedGroups.length, 0);
  }, results);

  await runScenario("skip recovery when tenant lacks whatsapp configuration", async () => {
    const sentMessages = [];
    testApi.setResolveTenantEvolutionConfig(() => null);
    testApi.setSendEvolutionTextMessage(async (payload) => {
      sentMessages.push(payload);
    });
    testApi.setMarkCartRecoveryState(async () => {});
    testApi.setDeleteCartDocs(async () => 0);
    testApi.setDb(
      createProcessDb({
        tenants: [
          {
            id: "tenant-1",
            data: { name: "Loja sem config" },
            customers: {},
            recoveryDocs: [
              createCartDoc({
                tenantId: "tenant-1",
                cartId: "cart-1",
                phone: "11999990000",
                updatedAt: "2026-04-09T08:00:00.000Z",
              }),
            ],
            expirationDocs: [],
          },
        ],
      }),
    );

    await withFrozenNow("2026-04-09T12:00:00.000Z", async () => {
      await abandonedHandler();
    });

    assert.strictEqual(sentMessages.length, 0);
  }, results);

  const failed = results.filter((result) => result.status === "failed");
  process.stdout.write(
    `\nResumo: ${results.length - failed.length}/${results.length} cenarios passaram.\n`,
  );

  if (failed.length > 0) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
