import React, { useMemo } from 'react';
import { Image, StyleSheet, View, useWindowDimensions } from 'react-native';
import { backdropSources } from '../../theme/backdrops';

const TILE = 160;

/**
 * Fixed film-grain overlay. Breaks up the flatness of large gradient fields and
 * hides the banding that vertical scrims produce on cheaper displays — the
 * difference between a background that looks printed and one that looks
 * rendered.
 *
 * The 160px noise texture is tiled by laying out explicit tiles rather than
 * with `resizeMode="repeat"`: repeat is documented as cross-platform but is
 * known to stop repeating horizontally on some physical Android devices, which
 * would smear one stretched tile across the screen instead of adding grain.
 */
export function Grain({ opacity = 0.5 }: { opacity?: number }) {
  const { width, height } = useWindowDimensions();

  const tiles = useMemo(() => {
    const columns = Math.ceil(width / TILE);
    const rows = Math.ceil(height / TILE);
    return Array.from({ length: columns * rows }, (_, i) => i);
  }, [width, height]);

  if (opacity <= 0) return null;

  return (
    <View pointerEvents="none" style={[StyleSheet.absoluteFill, styles.host, { opacity }]}>
      {tiles.map((i) => (
        <Image key={i} source={backdropSources.grain} style={styles.tile} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  host: { flexDirection: 'row', flexWrap: 'wrap', overflow: 'hidden' },
  tile: { width: TILE, height: TILE },
});
