#!/usr/bin/env node

const {execFileSync} = require("node:child_process");
const admin = require("firebase-admin");

const DEFAULT_PROJECT_ID = process.env.FIRESTORE_PROJECT_ID || "saas-manu-project";

function normalizeSearchText(value) {
  const accentsIn = "áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ";
  const accentsOut = "aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC";

  const normalized = String(value || "")
    .trim()
    .toLowerCase()
    .split("")
    .map((char) => {
      const accentIndex = accentsIn.indexOf(char);
      return accentIndex >= 0 ? accentsOut[accentIndex] : char;
    })
    .join("");

  return normalized.replace(/[^a-z0-9\s-]/g, " ").replace(/\s+/g, " ").trim();
}

function asStringList(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => String(item || "").trim())
      .filter(Boolean);
  }

  if (typeof value === "string") {
    return value
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
  }

  return [];
}

function buildSearchFields(product) {
  const sources = [
    product.name,
    product.sku,
    product.category,
    product.color,
    product.size,
    product.description,
    ...asStringList(product.tags),
  ];

  const tokens = new Set();
  for (const source of sources) {
    const normalized = normalizeSearchText(source);
    if (!normalized) continue;

    normalized.split(" ").forEach((token) => {
      if (token.length >= 2) {
        tokens.add(token);
      }
    });

    tokens.add(normalized);
  }

  const searchText = normalizeSearchText(sources.join(" "));
  return {
    search_text: searchText,
    search_tokens: Array.from(tokens).sort(),
  };
}

function arrayEquals(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) {
    return false;
  }

  return a.every((value, index) => value === b[index]);
}

function getProjectId() {
  return String(process.env.GOOGLE_CLOUD_PROJECT || DEFAULT_PROJECT_ID).trim();
}

function parseFirestoreValue(field) {
  if (!field || typeof field !== "object") return null;

  if (field.stringValue !== undefined) return field.stringValue;
  if (field.integerValue !== undefined) return Number(field.integerValue);
  if (field.doubleValue !== undefined) return Number(field.doubleValue);
  if (field.booleanValue !== undefined) return field.booleanValue;
  if (field.timestampValue !== undefined) return field.timestampValue;
  if (field.nullValue !== undefined) return null;

  if (field.arrayValue) {
    return (field.arrayValue.values || []).map((value) => parseFirestoreValue(value));
  }

  if (field.mapValue) {
    const output = {};
    for (const [key, value] of Object.entries(field.mapValue.fields || {})) {
      output[key] = parseFirestoreValue(value);
    }
    return output;
  }

  return null;
}

function parseFirestoreDocument(document) {
  const data = {};
  for (const [key, value] of Object.entries(document.fields || {})) {
    data[key] = parseFirestoreValue(value);
  }
  return data;
}

function toFirestoreValue(value) {
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((item) => toFirestoreValue(item)),
      },
    };
  }

  if (typeof value === "string") {
    return {stringValue: value};
  }

  if (typeof value === "number") {
    if (Number.isInteger(value)) return {integerValue: String(value)};
    return {doubleValue: value};
  }

  if (typeof value === "boolean") {
    return {booleanValue: value};
  }

  if (value && typeof value === "object") {
    const fields = {};
    for (const [key, entry] of Object.entries(value)) {
      fields[key] = toFirestoreValue(entry);
    }
    return {mapValue: {fields}};
  }

  return {nullValue: null};
}

function loadAccessTokenFromGcloud() {
  const accessToken = execFileSync("gcloud", ["auth", "print-access-token"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();

  if (!accessToken) {
    throw new Error("Nao foi possivel obter access token do gcloud.");
  }

  return accessToken;
}

async function firestoreFetch(url, init = {}) {
  const response = await fetch(url, init);
  const rawText = await response.text();
  let data = null;

  try {
    data = rawText ? JSON.parse(rawText) : null;
  } catch (error) {
    data = rawText;
  }

  if (!response.ok) {
    const message =
      data && typeof data === "object"
        ? data.error?.message || data.message || JSON.stringify(data)
        : String(data || response.statusText);
    throw new Error(`Firestore REST ${response.status}: ${message}`);
  }

  return data;
}

async function listDocumentsRest({accessToken, parentPath}) {
  const projectId = getProjectId();
  const documents = [];
  let pageToken = "";

  while (true) {
    const params = new URLSearchParams({pageSize: "200"});
    if (pageToken) params.set("pageToken", pageToken);

    const url =
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${parentPath}` +
      `?${params.toString()}`;

    const payload = await firestoreFetch(url, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: "application/json",
      },
    });

    documents.push(...(payload.documents || []));
    pageToken = payload.nextPageToken || "";

    if (!pageToken) break;
  }

  return documents;
}

async function patchDocumentRest({accessToken, documentPath, fields}) {
  const projectId = getProjectId();
  const params = new URLSearchParams();
  Object.keys(fields).forEach((fieldPath) => {
    params.append("updateMask.fieldPaths", fieldPath);
  });

  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${documentPath}` +
    `?${params.toString()}`;

  const body = {
    fields: Object.fromEntries(
      Object.entries(fields).map(([key, value]) => [key, toFirestoreValue(value)]),
    ),
  };

  await firestoreFetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

async function runWithAdminSdk(tenantIdArg) {
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const tenantsRef = db.collection("tenants");
  const tenantDocs = tenantIdArg
    ? [await tenantsRef.doc(String(tenantIdArg).trim()).get()]
    : (await tenantsRef.get()).docs;

  const writer = db.bulkWriter();
  let tenantCount = 0;
  let productCount = 0;
  let updatedCount = 0;

  for (const tenantDoc of tenantDocs) {
    if (!tenantDoc.exists) continue;
    tenantCount += 1;

    const productsSnapshot = await tenantDoc.ref.collection("products").get();
    for (const productDoc of productsSnapshot.docs) {
      productCount += 1;
      const data = productDoc.data() || {};
      const nextFields = buildSearchFields(data);
      const currentTokens = asStringList(data.search_tokens);
      const currentText = String(data.search_text || "").trim();

      if (
        currentText === nextFields.search_text &&
        arrayEquals(currentTokens, nextFields.search_tokens)
      ) {
        continue;
      }

      writer.set(productDoc.ref, nextFields, {merge: true});
      updatedCount += 1;
    }
  }

  await writer.close();

  return {
    authMode: "admin_sdk",
    tenantCount,
    productCount,
    updatedCount,
    tenantScope: tenantIdArg || "all",
  };
}

async function runWithFirestoreRest(tenantIdArg) {
  const accessToken = loadAccessTokenFromGcloud();
  const tenantDocuments = tenantIdArg
    ? [
        {
          name: `projects/${getProjectId()}/databases/(default)/documents/tenants/${String(tenantIdArg).trim()}`,
        },
      ]
    : await listDocumentsRest({
        accessToken,
        parentPath: "tenants",
      });

  let tenantCount = 0;
  let productCount = 0;
  let updatedCount = 0;

  for (const tenantDocument of tenantDocuments) {
    const tenantId = tenantDocument.name?.split("/").pop();
    if (!tenantId) continue;
    tenantCount += 1;

    const productDocuments = await listDocumentsRest({
      accessToken,
      parentPath: `tenants/${tenantId}/products`,
    });

    for (const productDocument of productDocuments) {
      productCount += 1;
      const data = parseFirestoreDocument(productDocument);
      const nextFields = buildSearchFields(data);
      const currentTokens = asStringList(data.search_tokens);
      const currentText = String(data.search_text || "").trim();

      if (
        currentText === nextFields.search_text &&
        arrayEquals(currentTokens, nextFields.search_tokens)
      ) {
        continue;
      }

      const documentPath = productDocument.name
        .replace(/^projects\/[^/]+\/databases\/\(default\)\/documents\//, "");

      await patchDocumentRest({
        accessToken,
        documentPath,
        fields: nextFields,
      });
      updatedCount += 1;
    }
  }

  return {
    authMode: "firestore_rest_gcloud_token",
    tenantCount,
    productCount,
    updatedCount,
    tenantScope: tenantIdArg || "all",
  };
}

async function main() {
  const tenantIdArg = process.argv[2] || process.env.TENANT_ID || "";
  let result;

  try {
    result = await runWithAdminSdk(tenantIdArg);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const isCredentialError =
      message.includes("default credentials") ||
      message.includes("Could not load the default credentials");

    if (!isCredentialError) {
      throw error;
    }

    result = await runWithFirestoreRest(tenantIdArg);
  }

  console.log(
    JSON.stringify(
      {ok: true, ...result},
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(
    JSON.stringify(
      {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      },
      null,
      2,
    ),
  );
  process.exitCode = 1;
});
