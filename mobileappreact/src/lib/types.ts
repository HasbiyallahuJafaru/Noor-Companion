export type Role = 'user' | 'therapist' | 'admin';
export type SubscriptionTier = 'free' | 'paid';

export interface UserStreak {
  currentStreak: number;
  longestStreak: number;
  totalDays: number;
  lastEngagedAt?: string | null;
}

export interface UserModel {
  id: string;
  supabaseId: string;
  firstName: string;
  lastName: string;
  role: Role;
  subscriptionTier: SubscriptionTier;
  avatarUrl?: string | null;
  streak?: UserStreak | null;
}

export interface DhikrModel {
  id: string;
  title: string;
  arabicText: string;
  transliteration: string;
  translation: string;
  targetCount: number;
  tags: string[];
  audioUrl?: string | null;
}

export interface DuaModel {
  id: string;
  title: string;
  arabicText: string;
  transliteration: string;
  translation: string;
  occasion: string;
  tags: string[];
  audioUrl?: string | null;
  source?: string | null;
}

export interface VerseModel {
  number: number;
  arabicText: string;
  translation: string;
}

export interface RecitationModel {
  id: string;
  surahNumber: number;
  nameArabic: string;
  nameEnglish: string;
  verseCount: number;
  revelationType: 'Meccan' | 'Medinan';
  audioUrl?: string | null;
  verses?: VerseModel[];
}

export interface StreakModel {
  currentStreak: number;
  longestStreak: number;
  totalDays: number;
  lastEngagedAt?: string | null;
}

export interface PrayerTimesModel {
  fajr: string;
  sunrise: string;
  dhuhr: string;
  asr: string;
  maghrib: string;
  isha: string;
  date: string;
}

export interface TherapistModel {
  id: string;
  firstName: string;
  lastName: string;
  bio: string;
  specialisations: string[];
  qualifications: string[];
  languagesSpoken: string[];
  yearsExperience: number;
  sessionRateNgn: number;
  totalSessions: number;
  averageRating?: number | null;
  availabilityJson?: unknown;
  avatarUrl?: string | null;
}

export interface TherapistOwnProfile extends TherapistModel {
  status: 'pending' | 'active' | 'rejected';
  rejectionReason?: string | null;
}

export type CallStatus = 'initiated' | 'active' | 'completed' | 'missed' | 'cancelled';

export interface CallSessionSummary {
  id: string;
  status: CallStatus;
  createdAt: string;
  endedAt?: string | null;
  durationSeconds?: number | null;
  callerFirstName?: string | null;
  callerLastName?: string | null;
  callerAvatarUrl?: string | null;
  rating?: number | null;
  ratingComment?: string | null;
}

export type NotificationType =
  | 'streak_reminder'
  | 'session_incoming'
  | 'session_completed'
  | 'subscription_active'
  | 'therapist_approved'
  | 'therapist_rejected'
  | 'morning_reminder'
  | 'evening_reflection'
  | 'task_reminder'
  | 'therapist_available'
  | 'milestone_unlocked'
  | string;

export interface NotificationModel {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  isRead: boolean;
  createdAt: string;
  data?: Record<string, unknown> | null;
}

export interface Milestone {
  days: number;
  arabicName: string;
  englishName: string;
  arabicAyah: string;
  transliteration: string;
  translation: string;
  reference: string;
}

export const MILESTONES: Milestone[] = [
  {
    days: 7,
    arabicName: 'صَبْر',
    englishName: 'Sabr - Patience',
    arabicAyah: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    transliteration: "Yaaa ayyuhallazeena aamanus ta'eeaoo bis sabri was salaah; innal laaha ma'as saabireen",
    translation: 'O you who believe, seek help through patience and prayer. Indeed, Allah is with the patient.',
    reference: 'Surah Al-Baqarah 2:153',
  },
  {
    days: 30,
    arabicName: 'تَوْبَة',
    englishName: 'Tawbah - Repentance',
    arabicAyah: 'وَالَّذِينَ إِذَا فَعَلُوا فَاحِشَةً أَوْ ظَلَمُوا أَنفُسَهُمْ ذَكَرُوا اللَّهَ فَاسْتَغْفَرُوا لِذُنُوبِهِمْ',
    transliteration: "Wallazeena izaa fa'aloo faahishatan aw zalamoo anfusahum zakarul laaha fastaghfaroo lizunoobihim",
    translation: 'And those who, when they commit an immorality or wrong themselves, remember Allah and seek forgiveness for their sins.',
    reference: 'Surah Aal-Imran 3:135',
  },
  {
    days: 90,
    arabicName: 'إِسْتِقَامَة',
    englishName: 'Istiqamah - Steadfastness',
    arabicAyah: 'إِنَّ الَّذِينَ قَالُوا رَبُّنَا اللَّهُ ثُمَّ اسْتَقَامُوا تَتَنَزَّلُ عَلَيْهِمُ الْمَلَائِكَةُ أَلَّا تَخَافُوا وَلَا تَحْزَنُوا',
    transliteration: "Innal lazeena qaaloo Rabbunal laahu summastaqaamu tatanazzalu 'alaihimul malaaa'ikatu allaa takhaafoo wa laa tahzanoo",
    translation: 'Indeed, those who have said "Our Lord is Allah" and then remained steadfast, the angels descend upon them, saying, "Do not fear and do not grieve."',
    reference: 'Surah Fussilat 41:30',
  },
  {
    days: 180,
    arabicName: 'تَوَكُّل',
    englishName: 'Tawakkul - Trust in Allah',
    arabicAyah: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    transliteration: "Wa mai yatawakkal 'alal laahi fahuwa hasbuh",
    translation: 'And whoever places their trust in Allah, then He alone is sufficient for them.',
    reference: 'Surah At-Talaq 65:3',
  },
  {
    days: 365,
    arabicName: 'يَقِين',
    englishName: 'Yaqeen - Certainty',
    arabicAyah: 'أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ',
    transliteration: "Alaaa inna awliyaaa'al laahi laa khawfun 'alaihim wa laa hum yahzanoon",
    translation: 'Unquestionably, the allies of Allah, there will be no fear concerning them, nor will they grieve.',
    reference: 'Surah Yunus 10:62',
  },
];

/** Progress arc milestones (kept from Flutter app). */
export const ARC_MILESTONES = [7, 30, 90, 180, 365];

export interface InterventionTask {
  id: string;
  label: string;
  instruction: string;
  type: 'verbal' | 'physical' | 'timed';
  durationSeconds?: number;
}

export const INTERVENTION_TASKS: InterventionTask[] = [
  { id: 'tasbih', label: 'Tasbih', instruction: 'Recite SubhanAllah 33 times, slowly, letting each word settle.', type: 'verbal' },
  { id: 'istighfar', label: 'Istighfar', instruction: 'Say Astaghfirullah 100 times. Each repetition is a door opening.', type: 'verbal' },
  { id: 'salawat', label: 'Salawat', instruction: 'Send blessings upon the Prophet ﷺ 100 times until your heart softens.', type: 'verbal' },
  { id: 'ikhlas', label: 'Surah Ikhlas', instruction: 'Recite Surah Al-Ikhlas three times, with full presence.', type: 'verbal' },
  { id: 'ayat_kursi', label: 'Ayat al-Kursi', instruction: 'Recite Ayat al-Kursi once, slowly. It is a shield for the heart.', type: 'verbal' },
  { id: 'wudu', label: 'Wudu', instruction: 'Perform wudu with care. Let the water carry the heaviness away.', type: 'physical' },
  { id: 'nafl', label: 'Two Rakahs', instruction: 'Pray two rakabs of nafl, pouring your heart into the sujood.', type: 'physical' },
  { id: 'quran', label: 'Quran', instruction: 'Read one page of Quran, even slowly. Light enters with every letter.', type: 'physical' },
  { id: 'water', label: 'Drink Water', instruction: 'Drink a full glass of water, mindfully, in small sips.', type: 'physical' },
  { id: 'cold_water', label: 'Cold Water', instruction: 'Splash cold water on your face. Reset your nervous system.', type: 'physical' },
  { id: 'walk', label: 'Walk', instruction: 'Walk for five minutes. Movement is mercy for a restless mind.', type: 'timed', durationSeconds: 300 },
];

export interface AdminAnalytics {
  totalUsers: number;
  activeToday: number;
  paidSubscribers: number;
  totalTherapists: number;
  pendingTherapists: number;
  callSessionsThisMonth: number;
}

export interface AdminUser {
  id: string;
  firstName: string;
  lastName: string;
  role: Role;
  subscriptionTier: SubscriptionTier;
  isActive: boolean;
  createdAt: string;
  currentStreak?: number | null;
  lastEngagedAt?: string | null;
}

export interface AdminUserDetail extends AdminUser {
  supabaseId: string;
  longestStreak?: number | null;
  totalDays?: number | null;
}

export interface PendingTherapist {
  id: string;
  userId: string;
  firstName: string;
  lastName: string;
  bio: string;
  specialisations: string[];
  qualifications: string[];
  yearsExperience: number;
  sessionRateNgn: number;
  createdAt: string;
}

export interface AdminContentItem {
  id: string;
  title: string;
  category: string;
  tags: string[];
  isActive: boolean;
  sortOrder: number;
  createdAt: string;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
}
