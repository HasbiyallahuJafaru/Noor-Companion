import React from 'react';
import Svg, { Circle, Path } from 'react-native-svg';

export type Mood = 'great' | 'good' | 'okay' | 'low';

/** The four check-in states, in order, with the label the UI shows. */
export const MOOD_SCALE: { mood: Mood; label: string }[] = [
  { mood: 'great', label: 'Great' },
  { mood: 'good', label: 'Good' },
  { mood: 'okay', label: 'Okay' },
  { mood: 'low', label: 'Not good' },
];

/**
 * Drawn on a 24×24 grid so the strokes line up with the lucide icons used
 * everywhere else. Only the mouth and the eye treatment change between moods —
 * the head stays put, so the row reads as one scale rather than four pictures.
 */
const FACES: Record<Mood, { mouth: string; happyEyes?: boolean; brows?: string }> = {
  great: {
    mouth: 'M8 13.9c.9 2.1 2.2 3.2 4 3.2s3.1-1.1 4-3.2',
    happyEyes: true,
  },
  good: {
    mouth: 'M8.5 14.4c.8 1.5 1.9 2.2 3.5 2.2s2.7-.7 3.5-2.2',
  },
  okay: {
    mouth: 'M8.8 15.2h6.4',
  },
  low: {
    mouth: 'M8.5 16.4c.8-1.5 1.9-2.2 3.5-2.2s2.7.7 3.5 2.2',
    // Slanted inward-down, clearing the top of the 1.05r eyes at y=10.1.
    brows: 'M7.6 7.6l2.1.9M16.4 7.6l-2.1.9',
  },
};

/**
 * Mood check-in face. Replaces the emoji that used to sit in this row: emoji
 * render in the platform's own font, so they never matched the app's colour,
 * weight, or size and looked different on every device.
 */
export function MoodFace({
  mood,
  size = 24,
  color,
  strokeWidth = 1.7,
}: {
  mood: Mood;
  size?: number;
  color: string;
  strokeWidth?: number;
}) {
  const face = FACES[mood];

  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Circle cx={12} cy={12} r={9.2} stroke={color} strokeWidth={strokeWidth} />
      {face.happyEyes ? (
        // Arcs centred on the same 9.2 / 14.8 axes as the dot eyes, so the
        // face does not shift when the mood changes.
        <Path
          d="M7.7 10.7q1.5-2 3 0M13.3 10.7q1.5-2 3 0"
          stroke={color}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
        />
      ) : (
        <>
          <Circle cx={9.2} cy={10.1} r={1.05} fill={color} />
          <Circle cx={14.8} cy={10.1} r={1.05} fill={color} />
        </>
      )}
      {face.brows && (
        <Path d={face.brows} stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
      )}
      <Path
        d={face.mouth}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  );
}
