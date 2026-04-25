/**
 * Supabase admin client — uses the service role key.
 * Bypasses Row Level Security. Used only in the backend.
 * Provides: token verification, user metadata updates, auth admin operations.
 */

'use strict';

const { createClient } = require('@supabase/supabase-js');
const { env } = require('./env');

const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

module.exports = { supabase };
