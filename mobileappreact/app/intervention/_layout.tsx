import { Stack } from 'expo-router';

export default function InterventionLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: 'transparent' },
        animation: 'fade',
        animationDuration: 300,
        gestureEnabled: false,
        fullScreenGestureEnabled: false,
      }}
    />
  );
}
