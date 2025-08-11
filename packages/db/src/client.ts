import { createClient } from "@vercel/postgres";
import { drizzle } from "drizzle-orm/vercel-postgres";

import * as schema from "./schema";

// Log the PostgreSQL URL being used
console.log("🔍 Database connection - POSTGRES_URL:", process.env.POSTGRES_URL);
console.log("🔍 Database connection - POSTGRES_URL_NON_POOLED:", process.env.POSTGRES_URL?.replace(":6543", ":5432"));

// Create a client using createClient() instead of sql
const client = createClient({
  connectionString: process.env.POSTGRES_URL,
});

export const db = drizzle({
  client,
  schema,
  casing: "snake_case",
});
