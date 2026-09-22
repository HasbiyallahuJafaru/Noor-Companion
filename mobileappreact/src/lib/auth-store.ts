import { create } from 'zustand';
import { api } from './api';
import { supabase } from './supabase';
import { cacheGet, cacheKeys, cacheSet, cacheRemove } from './cache';
import type { UserModel } from './types';

export type AuthStatus = 'loading' | 'authenticated' | 'unauthenticated';

interface AuthState {
  status: AuthStatus;
  user: UserModel | null;
  onboarded: boolean;
  /** Bumped to force a refresh of queries keyed on the user. */
  init: () => Promise<void>;
  setOnboarded: (v: boolean) => Promise<void>;
  refreshUser: () => Promise<void>;
  signOut: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  status: 'loading',
  user: null,
  onboarded: false,

  init: async () => {
    try {
      const onboarded = (await cacheGet<boolean>(cacheKeys.onboarding)) ?? false;
      const { data } = await supabase.auth.getSession();
      const session = data.session;
      if (!session) {
        set({ status: 'unauthenticated', user: null, onboarded });
        return;
      }
      try {
        const user = await api.me();
        set({ status: 'authenticated', user, onboarded });
      } catch {
        // Network hiccup with a valid session: still let the user in with
        // a minimal profile; individual screens will show their own errors.
        const meta = session.user.user_metadata ?? {};
        set({
          status: 'authenticated',
          onboarded,
          user: {
            id: session.user.id,
            supabaseId: session.user.id,
            firstName: (meta.first_name as string) ?? '',
            lastName: (meta.last_name as string) ?? '',
            role: (meta.role as UserModel['role']) ?? 'user',
            subscriptionTier: 'free',
            streak: null,
          },
        });
      }
    } catch {
      set({ status: 'unauthenticated', user: null });
    }
  },

  setOnboarded: async (v) => {
    await cacheSet(cacheKeys.onboarding, v);
    set({ onboarded: v });
  },

  refreshUser: async () => {
    try {
      const user = await api.me();
      set({ user, status: 'authenticated' });
    } catch {
      // keep previous user state
    }
  },

  signOut: async () => {
    await supabase.auth.signOut();
    await cacheRemove(cacheKeys.onboarding);
    set({ status: 'unauthenticated', user: null, onboarded: false });
  },
}));

// Keep the store in sync with Supabase session lifecycle events.
useAuthStore.subscribe = useAuthStore.subscribe; // keep store hoisted
supabase.auth.onAuthStateChange((event) => {
  const s = useAuthStore;
  if (event === 'SIGNED_OUT') {
    s.setState({ status: 'unauthenticated', user: null, onboarded: false });
  } else if (event === 'TOKEN_REFRESHED' && s.getState().status === 'authenticated') {
    s.getState().refreshUser();
  }
});
