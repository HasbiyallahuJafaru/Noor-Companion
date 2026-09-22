import { config } from './config';
import * as fx from './fixtures';
import type { StreakModel } from './types';

const delay = (ms = 250) => new Promise((r) => setTimeout(r, ms));

/**
 * Fixture-backed implementation of the api surface for demo mode.
 * Mirrors every endpoint's response shape exactly.
 */
export const demoApi = {
  async me() {
    await delay(120);
    return fx.demoUser;
  },
  async registerFcmToken() {
    return { success: true };
  },
  async subscribeToken() {
    await delay(300);
    return { redirectUrl: 'https://demo-checkout.example/pay' };
  },

  async dhikr(tag?: string) {
    await delay();
    return tag ? fx.demoDhikr.filter((d) => d.tags.includes(tag)) : fx.demoDhikr;
  },
  async duas(occasion?: string) {
    await delay();
    return occasion ? fx.demoDuas.filter((d) => d.occasion === occasion) : fx.demoDuas;
  },
  async recitations() {
    await delay();
    return fx.demoRecitations;
  },
  async recordProgress(_contentId: string) {
    await delay(200);
    fx.demoStreak.currentStreak += 1;
    fx.demoStreak.totalDays += 1;
    return { streak: { ...fx.demoStreak } as StreakModel };
  },

  async prayerTimes() {
    await delay(150);
    return fx.demoPrayerTimes;
  },
  async surah(n: number) {
    await delay();
    return fx.demoSurah(n);
  },

  async myStreak() {
    await delay(100);
    return { ...fx.demoStreak };
  },

  async therapists(_params?: unknown) {
    await delay(300);
    return { therapists: fx.demoTherapists };
  },
  async therapist(id: string) {
    await delay(200);
    const t = fx.demoTherapists.find((x) => x.id === id);
    if (!t) throw new Error('Therapist not found');
    return t;
  },
  async myTherapistProfile() {
    await delay(250);
    return fx.demoOwnProfile;
  },
  async saveTherapistProfile(body: Record<string, unknown>) {
    await delay(400);
    Object.assign(fx.demoOwnProfile, body);
    return fx.demoOwnProfile;
  },

  async callToken(therapistProfileId: string) {
    await delay(400);
    return {
      sessionId: `demo-session-${Date.now()}`,
      channelName: `noor-${therapistProfileId}`,
      agoraToken: 'demo-token',
    };
  },
  async renewCallToken() {
    return { agoraToken: 'demo-token-renewed' };
  },
  async endCall() {
    await delay(200);
    return { durationSeconds: 240 };
  },
  async rateCall() {
    await delay(250);
    return { success: true };
  },
  async mySessions(page = 1) {
    await delay(250);
    const pageSize = 20;
    return {
      sessions: fx.demoSessions.slice((page - 1) * pageSize, page * pageSize),
      pagination: { page, limit: pageSize, total: fx.demoSessions.length },
    };
  },

  async notifications() {
    await delay(150);
    return {
      notifications: fx.demoNotifications,
      unreadCount: fx.demoNotifications.filter((n) => !n.isRead).length,
    };
  },
  async readAllNotifications() {
    fx.demoNotifications.forEach((n) => (n.isRead = true));
    return { success: true };
  },

  async adminAnalytics() {
    await delay(250);
    return fx.demoAnalytics;
  },
  async adminUsers(_params?: unknown) {
    await delay(250);
    return { users: fx.demoAdminUsers, pagination: { page: 1, limit: 20, total: fx.demoAdminUsers.length } };
  },
  async adminUser(id: string) {
    await delay(200);
    if (id === 'au-1') return fx.demoAdminUserDetail;
    return { ...fx.demoAdminUsers.find((u) => u.id === id) ?? fx.demoAdminUsers[0], supabaseId: 'sb-demo', longestStreak: 12, totalDays: 34 };
  },
  async adminUpdateUser(id: string, body: { isActive?: boolean; subscriptionTier?: 'free' | 'paid' }) {
    await delay(300);
    const u = fx.demoAdminUsers.find((x) => x.id === id);
    if (u) Object.assign(u, body);
    return fx.demoAdminUserDetail;
  },
  async adminPendingTherapists() {
    await delay(300);
    return fx.demoPendingTherapists;
  },
  async adminApproveTherapist(id: string) {
    await delay(300);
    const idx = fx.demoPendingTherapists.findIndex((t) => t.id === id);
    if (idx >= 0) fx.demoPendingTherapists.splice(idx, 1);
    return { success: true };
  },
  async adminRejectTherapist(id: string) {
    await delay(300);
    const idx = fx.demoPendingTherapists.findIndex((t) => t.id === id);
    if (idx >= 0) fx.demoPendingTherapists.splice(idx, 1);
    return { success: true };
  },
  async adminContent(_params?: unknown) {
    await delay(250);
    return { items: fx.demoContent, pagination: { page: 1, limit: 50, total: fx.demoContent.length } };
  },
  async adminAddContent(body: { title: string; category: string; tags: string[] }) {
    await delay(400);
    fx.demoContent.unshift({
      id: `ac-${Date.now()}`,
      title: body.title,
      category: body.category,
      tags: body.tags,
      isActive: true,
      sortOrder: 0,
      createdAt: new Date().toISOString(),
    });
    return { success: true };
  },
  async adminToggleContent(id: string, isActive: boolean) {
    await delay(150);
    const item = fx.demoContent.find((c) => c.id === id);
    if (item) item.isActive = isActive;
    return { success: true };
  },
  async adminBroadcast() {
    await delay(500);
    return { sent: 1247 };
  },
};

void config;
