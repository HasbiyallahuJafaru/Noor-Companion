import React from 'react';
import { Text, StyleSheet, View, Pressable } from 'react-native';
import { Tabs, router } from 'expo-router';
import { BlurView } from 'expo-blur';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  interpolate,
} from 'react-native-reanimated';
import { Home, Sparkles, BookOpen, HeartHandshake, User, LayoutDashboard, ShieldCheck } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { useAuthStore } from '../../src/lib/auth-store';
import { spring } from '../../src/theme/motion';
import { useNotifications } from '../../src/lib/queries';
import { haptic } from '../../src/lib/haptics';

const ICONS: Record<string, typeof Home> = {
  index: Home,
  dhikr: Sparkles,
  quran: BookOpen,
  therapists: HeartHandshake,
  dashboard: LayoutDashboard,
  admin: ShieldCheck,
  profile: User,
};

const LABELS: Record<string, string> = {
  index: 'Home',
  dhikr: 'Dhikr',
  quran: 'Quran',
  therapists: 'Therapists',
  dashboard: 'Dashboard',
  admin: 'Admin',
  profile: 'Profile',
};

function TabItem({
  Icon,
  label,
  focused,
  onPress,
}: {
  Icon: typeof Home;
  label: string;
  focused: boolean;
  onPress: () => void;
}) {
  const { palette, type, radius } = useTheme();
  const progress = useSharedValue(0);

  React.useEffect(() => {
    progress.value = withSpring(focused ? 1 : 0, spring.snappy);
  }, [focused, progress]);

  const glyphStyle = useAnimatedStyle(() => ({
    transform: [
      { translateY: interpolate(progress.value, [0, 1], [0, -2]) },
      { scale: interpolate(progress.value, [0, 1], [1, 1.06]) },
    ],
  }));
  const pillStyle = useAnimatedStyle(() => ({
    opacity: progress.value,
    transform: [{ scale: interpolate(progress.value, [0, 1], [0.6, 1]) }],
  }));

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={focused ? { selected: true } : {}}
      accessibilityLabel={label}
      onPress={() => {
        haptic.light();
        onPress();
      }}
      style={styles.item}
      hitSlop={4}
    >
      {focused && (
        <Animated.View
          style={[
            styles.activePill,
            pillStyle,
            {
              backgroundColor: palette.isDark ? palette.tealSoft : palette.ink,
              borderRadius: radius.pill,
            },
          ]}
        />
      )}
      <Animated.View style={[styles.iconWrap, glyphStyle]}>
        <Icon
          size={22}
          color={focused ? (palette.isDark ? palette.teal : '#FFFFFF') : palette.textMuted}
          strokeWidth={focused ? 2.2 : 1.75}
        />
      </Animated.View>
      <Text
        numberOfLines={1}
        adjustsFontSizeToFit
        minimumFontScale={0.78}
        style={[type.micro(focused ? (palette.isDark ? palette.teal : '#FFFFFF') : palette.textMuted), styles.label]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

/* eslint-disable-next-line @typescript-eslint/no-explicit-any */
function visibleTabNames(role?: string): Set<string> {
  const visible = new Set<string>(['index', 'dhikr', 'profile']);
  if (role === 'user') {
    visible.add('quran');
    visible.add('therapists');
  }
  if (role === 'therapist') visible.add('dashboard');
  if (role === 'admin') visible.add('admin');
  return visible;
}

/**
 * Absolute hrefs per tab. The home screen is named "index" but its URL is the
 * group root, so navigating by screen name alone would target an unmatched
 * "/index" route.
 */
const TAB_HREFS: Record<string, string> = {
  index: '/(tabs)',
  dhikr: '/(tabs)/dhikr',
  quran: '/(tabs)/quran',
  therapists: '/(tabs)/therapists',
  dashboard: '/(tabs)/dashboard',
  admin: '/(tabs)/admin',
  profile: '/(tabs)/profile',
};

/* eslint-disable-next-line @typescript-eslint/no-explicit-any */
function TabBarComponent(props: any) {
  const { palette, radius, shadows } = useTheme();
  const user = useAuthStore((s) => s.user);
  const { data } = useNotifications(user != null);
  const unread = data?.unreadCount ?? 0;
  const visible = visibleTabNames(user?.role);

  return (
    <View pointerEvents="box-none" style={styles.barHost}>
      <View pointerEvents="box-none" style={styles.bellSlot}>
        {unread > 0 && <View style={[styles.bellDot, { backgroundColor: palette.danger }]} />}
      </View>
      <BlurView
        intensity={palette.isDark ? 40 : 60}
        tint={palette.isDark ? 'dark' : 'light'}
        style={[
          styles.barBlur,
          {
            borderRadius: radius.xl,
            borderColor: palette.glassBorder,
            backgroundColor: palette.surfaceGlassStrong,
          },
          shadows.lg,
        ]}
      >
        <View style={styles.row}>
          {props.state.routes
            .map((route: { key: string; name: string }, i: number) => ({ route, i }))
            .filter(({ route }: { route: { name: string } }) => visible.has(route.name))
            .map(({ route, i }: { route: { key: string; name: string }; i: number }) => {
              const focused = i === props.state.index;
              const Icon = ICONS[route.name] ?? Home;
              return (
                <TabItem
                  key={route.key}
                  Icon={Icon}
                  label={LABELS[route.name] ?? route.name}
                  focused={focused}
                  onPress={() => router.navigate((TAB_HREFS[route.name] ?? route.name) as never)}
                />
              );
            })}
        </View>
      </BlurView>
    </View>
  );
}

export default function TabsLayout() {
  const user = useAuthStore((s) => s.user);

  // Every tab file must be declared; hidden ones get href: null so Expo Router
  // does not auto-register them for every role.
  const visible = new Set<string>(['index', 'dhikr', 'profile']);
  if (user?.role === 'user') { visible.add('quran'); visible.add('therapists'); }
  if (user?.role === 'therapist') visible.add('dashboard');
  if (user?.role === 'admin') visible.add('admin');

  return (
    <Tabs screenOptions={{ headerShown: false }} tabBar={(props) => <TabBarComponent {...props} />}>
      {['index', 'dhikr', 'quran', 'therapists', 'dashboard', 'admin', 'profile'].map((name) => (
        <Tabs.Screen
          key={name}
          name={name}
          options={visible.has(name) ? {} : { href: null }}
        />
      ))}
    </Tabs>
  );
}

const styles = StyleSheet.create({
  barHost: {
    position: 'absolute',
    left: 20,
    right: 20,
    bottom: 16,
  },
  bellSlot: {
    alignSelf: 'flex-end',
    height: 10,
    justifyContent: 'flex-end',
    paddingRight: 14,
  },
  bellDot: { width: 10, height: 10, borderRadius: 5 },
  barBlur: {
    borderWidth: 1,
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
    height: 70,
    alignItems: 'center',
  },
  item: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    height: '100%',
    gap: 3,
  },
  activePill: {
    position: 'absolute',
    left: 3,
    right: 3,
    top: 8,
    bottom: 8,
  },
  iconWrap: { height: 24, justifyContent: 'flex-end' },
  label: { fontSize: 9 },
});
