import type { Config } from "drizzle-kit";

if (!process.env.POSTGRES_URL) {
  throw new Error("Missing POSTGRES_URL");
}

const nonPoolingUrl = process.env.POSTGRES_URL.replace(":6543", ":5432");

// Log the URLs being used
console.log("🔍 Drizzle config - Original POSTGRES_URL:", process.env.POSTGRES_URL);
console.log("🔍 Drizzle config - Non-pooled URL:", nonPoolingUrl);

export default {
  schema: "./src/schema.ts",
  dialect: "postgresql",
  dbCredentials: { url: nonPoolingUrl },
  casing: "snake_case",
} satisfies Config;
