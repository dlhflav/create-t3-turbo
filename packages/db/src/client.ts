import { sql } from "@vercel/postgres";
import { drizzle } from "drizzle-orm/vercel-postgres";

import * as schema from "./schema";

// Log the PostgreSQL URL being used
console.log("🔍 Database connection - POSTGRES_URL:", process.env.POSTGRES_URL);
console.log("🔍 Database connection - POSTGRES_URL_NON_POOLED:", process.env.POSTGRES_URL?.replace(":6543", ":5432"));

export const db = drizzle({
  client: sql,
  schema,
  casing: "snake_case",
});
