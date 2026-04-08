#!/usr/bin/env node

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

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

async function main() {
  const tenantIdArg = process.argv[2] || process.env.TENANT_ID || "";
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

      writer.set(productDoc.ref, nextFields, { merge: true });
      updatedCount += 1;
    }
  }

  await writer.close();

  console.log(
    JSON.stringify(
      {
        ok: true,
        tenantCount,
        productCount,
        updatedCount,
        tenantScope: tenantIdArg || "all",
      },
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
