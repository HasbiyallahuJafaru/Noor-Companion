export const config = {
  apiBaseUrl: process.env.EXPO_PUBLIC_API_BASE_URL ?? 'http://localhost:3000/api/v1',
  supabaseUrl: process.env.EXPO_PUBLIC_SUPABASE_URL ?? '',
  supabaseAnonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? '',
  websiteUrl: process.env.EXPO_PUBLIC_WEBSITE_URL ?? 'https://noorcompanion.netlify.app',
  /** Deep link scheme for the Paystack payment return (see app.json "scheme"). */
  paymentSuccessScheme: 'noorcompanion://payment-success',
  monthlyPriceNgn: 5000,
  /**
   * Demo mode: run the full UI against realistic fixtures with no backend.
   * Set EXPO_PUBLIC_DEMO_MODE=0 and provide Supabase + API env vars for production.
   */
  demoMode: process.env.EXPO_PUBLIC_DEMO_MODE !== '0',
};
