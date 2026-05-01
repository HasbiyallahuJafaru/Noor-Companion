'use strict';

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const { Client } = require('pg');

const EMAIL = 'jafaruhasbiyallahu@gmail.com';

async function main() {
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  // 1. Find the user in Supabase Auth
  const { data: { users }, error: listError } = await supabase.auth.admin.listUsers();
  if (listError) throw listError;

  const supabaseUser = users.find(u => u.email === EMAIL);
  if (!supabaseUser) throw new Error(`No Supabase Auth user found for ${EMAIL}`);
  console.log(`Found Supabase user: ${supabaseUser.id}`);

  // 2. Update user_metadata to set role = admin
  const { error: updateError } = await supabase.auth.admin.updateUserById(supabaseUser.id, {
    user_metadata: { ...supabaseUser.user_metadata, role: 'admin' },
  });
  if (updateError) throw updateError;
  console.log('Updated Supabase user_metadata: role = admin');

  // 3. Update the DB User record directly
  const connectionString = process.env.DIRECT_DATABASE_URL || process.env.DATABASE_URL;
  const client = new Client({ connectionString, ssl: { rejectUnauthorized: false } });
  await client.connect();

  const res = await client.query(
    `UPDATE "User" SET "role" = 'admin', "updatedAt" = NOW()
     WHERE "supabaseId" = $1
     RETURNING "id", "role"`,
    [supabaseUser.id]
  );

  if (res.rowCount === 0) {
    console.log('No DB row found — will be created as admin on next login.');
  } else {
    console.log(`Updated DB User row: id=${res.rows[0].id}, role=${res.rows[0].role}`);
  }

  await client.end();
  console.log('Done. jafaruhasbiyallahu@gmail.com is now admin.');
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
