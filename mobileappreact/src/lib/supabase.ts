import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { config } from './config';

/**
 * Supabase is auth-only, matching the platform architecture: the Railway API
 * owns all app data. Sessions persist through AsyncStorage.
 *
 * The client is created lazily so a missing configuration degrades to the
 * signed-out state (with a clear message on sign-in) instead of crashing the
 * whole bundle at module scope.
 */
let client: SupabaseClient | null = null;

/** Role selector for demo sign-in: embed 'admin' or 'therapist' in the email. */
export let demoRole: 'user' | 'therapist' | 'admin' = 'user';

function demoSessionUser() {
  return {
    id: 'demo-supabase-1',
    user_metadata: { first_name: 'Yusuf', last_name: 'Abdallah', role: demoRole },
  };
}

function demoAuthClient(): SupabaseClient {
  const auth = {
    async getSession() {
      return { data: { session: { user: demoSessionUser() } }, error: null };
    },
    async signOut() {
      demoRole = 'user';
      return { error: null };
    },
    async signInWithPassword({ email }: { email: string }) {
      demoRole = email.includes('admin') ? 'admin' : email.includes('therapist') ? 'therapist' : 'user';
      return { data: { session: { user: demoSessionUser() }, user: demoSessionUser() }, error: null };
    },
    async signUp({ email }: { email: string }) {
      demoRole = email.includes('admin') ? 'admin' : email.includes('therapist') ? 'therapist' : 'user';
      return { data: { session: { user: demoSessionUser() }, user: demoSessionUser() }, error: null };
    },
    async resetPasswordForEmail() {
      return { data: {}, error: null };
    },
    onAuthStateChange(_cb: unknown) {
      return {
        data: {
          subscription: {
            unsubscribe() {},
          },
        },
      };
    },
  };
  return { auth } as unknown as SupabaseClient;
}

function getClient(): SupabaseClient {
  if (config.demoMode) return demoAuthClient();
  if (!client) {
    if (!config.supabaseUrl || !config.supabaseAnonKey) {
      throw new Error(
        'Supabase is not configured. Set EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY in .env',
      );
    }
    client = createClient(config.supabaseUrl, config.supabaseAnonKey, {
      auth: {
        storage: AsyncStorage,
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: false,
      },
    });
  }
  return client;
}

export const supabase = new Proxy({} as SupabaseClient, {
  get(_target, prop, receiver) {
    return Reflect.get(getClient(), prop, receiver);
  },
});
