import type {
  AdminAnalytics,
  AdminContentItem,
  AdminUser,
  AdminUserDetail,
  CallSessionSummary,
  DhikrModel,
  DuaModel,
  NotificationModel,
  PrayerTimesModel,
  RecitationModel,
  StreakModel,
  TherapistModel,
  TherapistOwnProfile,
  UserModel,
} from './types';

/**
 * Demo fixtures: realistic sample data mirroring the production API shapes so
 * the entire app is explorable without a backend (EXPO_PUBLIC_DEMO_MODE=1).
 */

const now = Date.now();
const hoursAgo = (h: number) => new Date(now - h * 3600_000).toISOString();

export const demoUser: UserModel = {
  id: 'demo-user-1',
  supabaseId: 'demo-supabase-1',
  firstName: 'Yusuf',
  lastName: 'Abdallah',
  role: 'user',
  subscriptionTier: 'paid',
  avatarUrl: null,
  streak: { currentStreak: 23, longestStreak: 41, totalDays: 187, lastEngagedAt: hoursAgo(5) },
};

export const demoTherapistUser: UserModel = {
  ...demoUser,
  role: 'therapist',
};

export const demoAdminUser: UserModel = {
  ...demoUser,
  role: 'admin',
};

export const demoDhikr: DhikrModel[] = [
  {
    id: 'dhikr-1',
    title: 'Morning Remembrance',
    arabicText: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
    transliteration: 'Asbahnaa wa asbahal-mulku lillaah',
    translation: 'We have entered the morning and with it all dominion belongs to Allah.',
    targetCount: 1,
    tags: ['morning', 'general'],
    audioUrl: null,
  },
  {
    id: 'dhikr-2',
    title: 'Sayyidul Istighfar',
    arabicText: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ',
    transliteration: 'Allaahumma anta rabbee laa ilaaha illaa ant',
    translation: 'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant.',
    targetCount: 1,
    tags: ['morning', 'forgiveness'],
    audioUrl: null,
  },
  {
    id: 'dhikr-3',
    title: 'Tasbih Fatimah',
    arabicText: 'سُبْحَانَ اللَّهِ',
    transliteration: 'Subhaanallah',
    translation: 'Glory be to Allah.',
    targetCount: 33,
    tags: ['general', 'evening'],
    audioUrl: null,
  },
  {
    id: 'dhikr-4',
    title: 'Evening Protection',
    arabicText: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ',
    transliteration: 'Amsaynaa wa amsal-mulku lillaah',
    translation: 'We have entered the evening and with it all dominion belongs to Allah.',
    targetCount: 1,
    tags: ['evening', 'general'],
    audioUrl: null,
  },
  {
    id: 'dhikr-5',
    title: 'Seeking Forgiveness',
    arabicText: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    transliteration: 'Astaghfirullaaha wa atoobu ilayh',
    translation: 'I seek Allah\u2019s forgiveness and turn to Him in repentance.',
    targetCount: 100,
    tags: ['forgiveness', 'general'],
    audioUrl: null,
  },
  {
    id: 'dhikr-6',
    title: 'Salawat',
    arabicText: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    transliteration: 'Allaahumma salli alaa Muhammad',
    translation: 'O Allah, send blessings upon Muhammad.',
    targetCount: 100,
    tags: ['general', 'morning', 'evening'],
    audioUrl: null,
  },
];

export const demoDuas: DuaModel[] = [
  {
    id: 'dua-1',
    title: 'Relief from Anxiety',
    arabicText: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
    transliteration: "Allaahumma innee a'oodhu bika minal-hammi wal-hazan",
    translation: 'O Allah, I seek refuge in You from anxiety and grief.',
    occasion: 'anxiety',
    tags: ['anxiety', 'protection'],
    audioUrl: null,
    source: 'Bukhari 8/154',
  },
  {
    id: 'dua-2',
    title: 'Before Eating',
    arabicText: 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
    transliteration: 'Bismillaahi wa alaa barakatillaah',
    translation: 'In the name of Allah and with the blessing of Allah.',
    occasion: 'eating',
    tags: ['daily'],
    audioUrl: null,
    source: 'Ibn Sunni 257',
  },
  {
    id: 'dua-3',
    title: 'Travel',
    arabicText: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا',
    transliteration: 'Subhaanal-ladhee sakhkhara lanaa haadhaa',
    translation: 'Glory to Him who has subjected this to us, and we could never have it by our efforts.',
    occasion: 'travel',
    tags: ['travel'],
    audioUrl: null,
    source: 'Muslim 2/978',
  },
  {
    id: 'dua-4',
    title: 'Morning Litany',
    arabicText: 'رَضِيتُ بِاللَّهِ رَبًّا وَبِالْإِسْلَامِ دِينًا',
    transliteration: 'Radeetu billaahi rabban wa bil-islaami deenan',
    translation: 'I am pleased with Allah as my Lord, Islam as my religion.',
    occasion: 'morning',
    tags: ['morning', 'protection'],
    audioUrl: null,
    source: 'Abu Dawud 4/351',
  },
  {
    id: 'dua-5',
    title: 'Evening Litany',
    arabicText: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ',
    transliteration: "Bismillaahil-ladhee laa yadurru ma'asmihi shay'",
    translation: 'In the name of Allah, with whose name nothing can cause harm.',
    occasion: 'evening',
    tags: ['evening', 'protection'],
    audioUrl: null,
    source: 'Abu Dawud 4/323',
  },
];

const SURAH_NAMES = [
  ['Al-Fatihah', 'الفاتحة', 7, 'Meccan'],
  ['Al-Baqarah', 'البقرة', 286, 'Medinan'],
  ['Aal-Imran', 'آل عمران', 200, 'Medinan'],
  ['An-Nisa', 'النساء', 176, 'Medinan'],
  ["Al-Ma'idah", 'المائدة', 120, 'Medinan'],
  ['Al-Anam', 'الأنعام', 165, 'Meccan'],
  ['Al-Araf', 'الأعراف', 206, 'Meccan'],
  ['Al-Anfal', 'الأنفال', 75, 'Medinan'],
  ['At-Tawbah', 'التوبة', 129, 'Medinan'],
  ['Yunus', 'يونس', 109, 'Meccan'],
] as const;

export const demoRecitations: RecitationModel[] = SURAH_NAMES.map(([name, arabic, count, type], i) => ({
  id: String(i + 1),
  surahNumber: i + 1,
  nameEnglish: name,
  nameArabic: arabic,
  verseCount: count,
  revelationType: type as 'Meccan' | 'Medinan',
  audioUrl: null,
}));

export function demoSurah(n: number): RecitationModel {
  const base = demoRecitations[Math.min(Math.max(n, 1), 114) - 1];
  return {
    ...base,
    audioUrl: null,
    verses: Array.from({ length: Math.min(base.verseCount, 10) }, (_, i) => ({
      number: i + 1,
      arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      translation: 'In the name of Allah, the Most Gracious, the Most Merciful.',
    })),
  };
}

export const demoPrayerTimes: PrayerTimesModel = {
  fajr: '05:32',
  sunrise: '06:48',
  dhuhr: '12:15',
  asr: '15:38',
  maghrib: '18:22',
  isha: '19:42',
  date: new Date().toISOString().slice(0, 10),
};

export const demoStreak: StreakModel = {
  currentStreak: 23,
  longestStreak: 41,
  totalDays: 187,
  lastEngagedAt: hoursAgo(5),
};

export const demoTherapists: TherapistModel[] = [
  {
    id: 'therapist-1',
    firstName: 'Amina',
    lastName: 'Suleiman',
    bio: 'Licensed clinical psychologist with eight years of experience supporting young Muslims through addiction recovery. I integrate CBT with faith-based frameworks, meeting you where you are without judgement.',
    specialisations: ['Addiction Recovery', 'Anxiety', 'Trauma'],
    qualifications: ['MSc Clinical Psychology', 'Certified CBT Practitioner'],
    languagesSpoken: ['English', 'Arabic', 'Hausa'],
    yearsExperience: 8,
    sessionRateNgn: 6000,
    totalSessions: 214,
    averageRating: 4.8,
    avatarUrl: null,
  },
  {
    id: 'therapist-2',
    firstName: 'Ibrahim',
    lastName: 'Okonkwo',
    bio: 'Addiction counsellor focused on relapse prevention and family reintegration. My sessions are structured, practical, and grounded in compassion.',
    specialisations: ['Addiction Counselling', 'Depression'],
    qualifications: ['BSc Psychology', 'ICAP Certified'],
    languagesSpoken: ['English', 'Igbo', 'Yoruba'],
    yearsExperience: 6,
    sessionRateNgn: 5000,
    totalSessions: 156,
    averageRating: 4.6,
    avatarUrl: null,
  },
  {
    id: 'therapist-3',
    firstName: 'Khadija',
    lastName: 'Bello',
    bio: 'Psychotherapist specialising in behavioural habits and stress. I help clients rebuild routines with sustainable, mercy-centred approaches.',
    specialisations: ['Habit Change', 'Stress', 'Grief'],
    qualifications: ['MA Counselling Psychology'],
    languagesSpoken: ['English', 'French'],
    yearsExperience: 10,
    sessionRateNgn: 7500,
    totalSessions: 302,
    averageRating: 4.9,
    avatarUrl: null,
  },
];

export const demoOwnProfile: TherapistOwnProfile = {
  ...demoTherapists[1],
  status: 'active',
};

export const demoSessions: CallSessionSummary[] = [
  { id: 'sess-1', status: 'completed', createdAt: hoursAgo(20), endedAt: hoursAgo(19), durationSeconds: 1980, callerFirstName: 'Maryam', callerLastName: 'Lawal', rating: 5, ratingComment: 'Very understanding.' },
  { id: 'sess-2', status: 'completed', createdAt: hoursAgo(70), endedAt: hoursAgo(69), durationSeconds: 2450, callerFirstName: 'Ali', callerLastName: 'Hassan', rating: 4 },
  { id: 'sess-3', status: 'missed', createdAt: hoursAgo(96), callerFirstName: 'Zaid', callerLastName: 'Umar' },
  { id: 'sess-4', status: 'completed', createdAt: hoursAgo(140), endedAt: hoursAgo(139), durationSeconds: 1740, callerFirstName: 'Fatima', callerLastName: 'Sani', rating: 5 },
];

export const demoNotifications: NotificationModel[] = [
  { id: 'n-1', type: 'streak_reminder', title: 'Your streak is waiting', body: 'Complete a dhikr today to keep your 23-day streak alive.', isRead: false, createdAt: hoursAgo(2) },
  { id: 'n-2', type: 'session_completed', title: 'Session completed', body: 'Your session with Amina Suleiman lasted 33 minutes.', isRead: false, createdAt: hoursAgo(26) },
  { id: 'n-3', type: 'subscription_active', title: 'Premium activated', body: 'Welcome to Noor Companion Premium. Enjoy full access.', isRead: true, createdAt: hoursAgo(50) },
  { id: 'n-4', type: 'morning_reminder', title: 'Morning adhkar', body: 'Start your day with the morning remembrances.', isRead: true, createdAt: hoursAgo(30) },
  { id: 'n-5', type: 'therapist_available', title: 'Therapist available', body: 'Khadija Bello has an opening this afternoon.', isRead: true, createdAt: hoursAgo(74) },
];

export const demoAnalytics: AdminAnalytics = {
  totalUsers: 1284,
  activeToday: 342,
  paidSubscribers: 216,
  totalTherapists: 18,
  pendingTherapists: 3,
  callSessionsThisMonth: 89,
};

export const demoAdminUsers: AdminUser[] = [
  { id: 'au-1', firstName: 'Maryam', lastName: 'Lawal', role: 'user', subscriptionTier: 'paid', isActive: true, createdAt: hoursAgo(500), currentStreak: 64, lastEngagedAt: hoursAgo(1) },
  { id: 'au-2', firstName: 'Ali', lastName: 'Hassan', role: 'user', subscriptionTier: 'free', isActive: true, createdAt: hoursAgo(1200), currentStreak: 3, lastEngagedAt: hoursAgo(9) },
  { id: 'au-3', firstName: 'Amina', lastName: 'Suleiman', role: 'therapist', subscriptionTier: 'paid', isActive: true, createdAt: hoursAgo(2400), currentStreak: 0 },
  { id: 'au-4', firstName: 'Zaid', lastName: 'Umar', role: 'user', subscriptionTier: 'free', isActive: false, createdAt: hoursAgo(3000), currentStreak: 0, lastEngagedAt: hoursAgo(800) },
];

export const demoAdminUserDetail: AdminUserDetail = {
  ...demoAdminUsers[0],
  supabaseId: 'sb-88f2-4d31-a771',
  longestStreak: 91,
  totalDays: 210,
};

export const demoPendingTherapists = [
  {
    id: 'pt-1',
    userId: 'au-9',
    firstName: 'Salem',
    lastName: 'Idris',
    bio: 'Counselling psychologist with a focus on youth behavioural health and substance recovery. Trained in motivational interviewing.',
    specialisations: ['Addiction Recovery', 'Youth Counselling'],
    qualifications: ['MSc Counselling Psychology'],
    yearsExperience: 4,
    sessionRateNgn: 4500,
    createdAt: hoursAgo(30),
  },
  {
    id: 'pt-2',
    userId: 'au-10',
    firstName: 'Hauwa',
    lastName: 'Mohammed',
    bio: 'Clinical social worker supporting families through recovery. Ten years of practice across community and private settings.',
    specialisations: ['Family Therapy', 'Depression'],
    qualifications: ['MSW Clinical Social Work'],
    yearsExperience: 10,
    sessionRateNgn: 7000,
    createdAt: hoursAgo(52),
  },
];

export const demoContent: AdminContentItem[] = [
  { id: 'ac-1', title: 'Morning Remembrance', category: 'dhikr', tags: ['morning'], isActive: true, sortOrder: 1, createdAt: hoursAgo(400) },
  { id: 'ac-2', title: 'Relief from Anxiety', category: 'duas', tags: ['anxiety'], isActive: true, sortOrder: 2, createdAt: hoursAgo(390) },
  { id: 'ac-3', title: 'Sayyidul Istighfar', category: 'dhikr', tags: ['forgiveness'], isActive: false, sortOrder: 3, createdAt: hoursAgo(300) },
];
