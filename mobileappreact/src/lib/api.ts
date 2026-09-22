import { supabase } from './supabase';
import { config } from './config';
import { demoApi } from './demo-api';
import type {
  AdminAnalytics,
  AdminContentItem,
  AdminUser,
  AdminUserDetail,
  CallSessionSummary,
  DhikrModel,
  DuaModel,
  NotificationModel,
  PaginationMeta,
  PendingTherapist,
  PrayerTimesModel,
  RecitationModel,
  StreakModel,
  TherapistModel,
  TherapistOwnProfile,
  UserModel,
} from './types';

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

type Query = Record<string, string | number | boolean | undefined | null>;

function buildUrl(path: string, query?: Query): string {
  const url = new URL(`${config.apiBaseUrl}${path}`);
  if (query) {
    for (const [k, v] of Object.entries(query)) {
      if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v));
    }
  }
  return url.toString();
}

async function request<T>(
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE',
  path: string,
  opts: { query?: Query; body?: unknown } = {},
): Promise<T> {
  const { data: { session } } = await supabase.auth.getSession();
  let res: Response;
  try {
    res = await fetch(buildUrl(path, opts.query), {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(session?.access_token
          ? { Authorization: `Bearer ${session.access_token}` }
          : {}),
      },
      body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
    });
  } catch {
    throw new ApiError('Network unavailable. Check your connection.', 0);
  }

  if (res.status === 401) {
    await supabase.auth.signOut();
    throw new ApiError('Session expired', 401);
  }

  const json = await res.json().catch(() => null);
  if (!res.ok) {
    const message =
      (json && typeof json === 'object' && 'message' in json && String((json as { message: unknown }).message)) ||
      (json && typeof json === 'object' && 'error' in json && String((json as { error: unknown }).error)) ||
      `Request failed (${res.status})`;
    throw new ApiError(message, res.status);
  }

  // Platform responses wrap payloads in { data: ... }.
  if (json && typeof json === 'object' && 'data' in json) {
    return (json as { data: T }).data;
  }
  return json as T;
}

const realApi = {
  // ── Users ────────────────────────────────────────────────────────────────
  me: () => request<UserModel>('GET', '/users/me'),
  registerFcmToken: (fcmToken: string) =>
    request<{ success: boolean }>('POST', '/users/me/fcm-token', { body: { fcmToken } }),
  subscribeToken: () =>
    request<{ redirectUrl: string }>('POST', '/users/me/subscribe-token'),

  // ── Content ──────────────────────────────────────────────────────────────
  dhikr: (tag?: string) =>
    request<DhikrModel[]>('GET', '/content/dhikr', { query: { tag } }),
  duas: (tag?: string) =>
    request<DuaModel[]>('GET', '/content/duas', { query: { tag } }),
  recitations: () => request<RecitationModel[]>('GET', '/content/recitations'),
  recordProgress: (contentId: string) =>
    request<{ streak: StreakModel }>('POST', `/content/${contentId}/progress`),

  // ── Islamic services ─────────────────────────────────────────────────────
  prayerTimes: (lat?: number, lng?: number, date?: string) =>
    request<PrayerTimesModel>('GET', '/islamic/prayer-times', {
      query: { lat, lng, date },
    }),
  surah: (surahNumber: number) =>
    request<RecitationModel>('GET', `/islamic/quran/${surahNumber}`),

  // ── Streaks ──────────────────────────────────────────────────────────────
  myStreak: () => request<StreakModel>('GET', '/streaks/me'),

  // ── Therapists ───────────────────────────────────────────────────────────
  therapists: (params: { page?: number; limit?: number; specialisation?: string; language?: string } = {}) =>
    request<{ therapists: TherapistModel[] }>('GET', '/therapists', { query: params }),
  therapist: (id: string) => request<TherapistModel>('GET', `/therapists/${id}`),
  myTherapistProfile: () => request<TherapistOwnProfile>('GET', '/therapists/me'),
  saveTherapistProfile: (body: {
    bio: string;
    specialisations: string[];
    qualifications: string[];
    languagesSpoken: string[];
    yearsExperience: number;
    sessionRateNgn: number;
  }) => request<TherapistOwnProfile>('POST', '/therapists/profile', { body }),

  // ── Calls ────────────────────────────────────────────────────────────────
  callToken: (therapistProfileId: string) =>
    request<{ sessionId: string; channelName: string; agoraToken: string }>(
      'POST',
      '/calls/token',
      { body: { therapistProfileId } },
    ),
  renewCallToken: (sessionId: string) =>
    request<{ agoraToken: string }>('POST', `/calls/${sessionId}/renew-token`),
  endCall: (sessionId: string) =>
    request<{ durationSeconds: number }>('POST', `/calls/${sessionId}/end`),
  rateCall: (sessionId: string, rating: number, comment?: string) =>
    request<{ success: boolean }>('POST', `/calls/${sessionId}/rate`, {
      body: { rating, comment },
    }),
  mySessions: (page = 1, limit = 20) =>
    request<{ sessions: CallSessionSummary[]; pagination: PaginationMeta }>(
      'GET',
      '/calls/my-sessions',
      { query: { page, limit } },
    ),

  // ── Notifications ────────────────────────────────────────────────────────
  notifications: (page = 1, limit = 20) =>
    request<{ notifications: NotificationModel[]; unreadCount: number }>(
      'GET',
      '/notifications',
      { query: { page, limit } },
    ),
  readAllNotifications: () =>
    request<{ success: boolean }>('POST', '/notifications/read-all'),

  // ── Admin ────────────────────────────────────────────────────────────────
  adminAnalytics: () => request<AdminAnalytics>('GET', '/admin/analytics'),
  adminUsers: (params: {
    role?: string;
    subscriptionTier?: string;
    search?: string;
    page?: number;
    limit?: number;
  } = {}) =>
    request<{ users: AdminUser[]; pagination: PaginationMeta }>('GET', '/admin/users', {
      query: params,
    }),
  adminUser: (id: string) => request<AdminUserDetail>('GET', `/admin/users/${id}`),
  adminUpdateUser: (
    id: string,
    body: { isActive?: boolean; subscriptionTier?: 'free' | 'paid' },
  ) => request<AdminUserDetail>('PATCH', `/admin/users/${id}`, { body }),
  adminPendingTherapists: () =>
    request<PendingTherapist[]>('GET', '/admin/therapists/pending'),
  adminApproveTherapist: (id: string) =>
    request<{ success: boolean }>('POST', `/admin/therapists/${id}/approve`),
  adminRejectTherapist: (id: string, reason: string) =>
    request<{ success: boolean }>('POST', `/admin/therapists/${id}/reject`, {
      body: { reason },
    }),
  adminContent: (params: { category?: string; page?: number; limit?: number } = {}) =>
    request<{ items: AdminContentItem[]; pagination: PaginationMeta }>(
      'GET',
      '/admin/content',
      { query: params },
    ),
  adminAddContent: (body: {
    title: string;
    arabicText: string;
    transliteration: string;
    translation: string;
    category: string;
    tags: string[];
    audioUrl?: string;
    sortOrder: number;
  }) => request<{ success: boolean }>('POST', '/admin/content', { body }),
  adminToggleContent: (id: string, isActive: boolean) =>
    request<{ success: boolean }>('PATCH', `/admin/content/${id}`, {
      body: { isActive },
    }),
  adminBroadcast: (body: { title: string; body: string; targetRole: string }) =>
    request<{ sent: number }>('POST', '/admin/notifications/broadcast', { body }),
};

export type { PendingTherapist };

export const api: typeof realApi = config.demoMode ? demoApi : realApi;
