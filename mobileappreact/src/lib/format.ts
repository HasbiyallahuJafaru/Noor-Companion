export function relativeTime(iso: string): string {
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return '';
  const diff = Date.now() - then;
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days === 1) return 'Yesterday';
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months}mo ago`;
  return new Date(iso).toLocaleDateString();
}

export function greeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/** Time-of-day content tag: mirrors the Flutter home screen logic. */
export function timeTag(): 'morning' | 'evening' | 'general' {
  const h = new Date().getHours();
  if (h < 12) return 'morning';
  if (h >= 15.5) return 'evening';
  return 'general';
}

export function formatNgn(n: number): string {
  return `₦${n.toLocaleString('en-NG')}`;
}

export function formatNgnShort(n: number): string {
  return `₦${(n / 1000).toFixed(0)}k`;
}

export function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m >= 60) {
    const h = Math.floor(m / 60);
    return `${h}h ${m % 60}m`;
  }
  return `${m}m ${String(s).padStart(2, '0')}s`;
}

export function mmss(seconds: number): string {
  return `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
}

export function initials(first: string, last: string): string {
  return `${first?.[0] ?? ''}${last?.[0] ?? ''}`.toUpperCase() || '?';
}

export function timeToMinutes(hhmm: string): number {
  const [h, m] = hhmm.split(':').map((v) => parseInt(v, 10));
  if (Number.isNaN(h) || Number.isNaN(m)) return 0;
  return h * 60 + m;
}

/** Countdown string to the next occurrence of an "HH:MM" time today. */
export function countdownTo(hhmm: string, now = new Date()): string {
  const target = timeToMinutes(hhmm);
  const current = now.getHours() * 60 + now.getMinutes();
  let diff = target - current;
  if (diff <= 0) diff += 24 * 60;
  return `${Math.floor(diff / 60)}h ${diff % 60}m`;
}
