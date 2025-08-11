import { db } from './packages/db/src/client.ts';
import { sql } from 'drizzle-orm';

async function testConnection() {
  try {
    console.log('Testing database connection...');
    
    // Test a simple query
    const result = await db.execute(sql`SELECT NOW() as current_time`);
    console.log('✅ Database connection successful!');
    console.log('Current time from database:', result.rows[0].current_time);
    
    // Test if tables exist
    const tables = await db.execute(sql`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    
    console.log('📋 Available tables:');
    tables.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });
    
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
}

testConnection();