import type { Config } from "drizzle-kit";

if (!process.env.POSTGRES_URL) {
  throw new Error("Missing POSTGRES_URL");
}

// Log the URL being used
console.log("🔍 Drizzle config - POSTGRES_URL:", process.env.POSTGRES_URL);

export default {
  schema: "./src/schema.ts",
  dialect: "postgresql",
  dbCredentials: { url: process.env.POSTGRES_URL },
  casing: "snake_case",
} satisfies Config;
