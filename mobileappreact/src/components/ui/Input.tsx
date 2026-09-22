import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, StyleProp, ViewStyle, TextInputProps, Platform } from 'react-native';
import { Eye, EyeOff } from 'lucide-react-native';
import { useTheme } from '../../theme';
import { PressableScale } from './PressableScale';

interface InputProps extends TextInputProps {
  label: string;
  error?: string | null;
  hint?: string;
  secure?: boolean;
  style?: StyleProp<ViewStyle>;
  multiline?: boolean;
}

/**
 * Label above, helper below, error below in danger color. Focus draws a teal
 * ring; the field itself is a solid surface card.
 */
export function Input({ label, error, hint, secure, style, multiline, ...rest }: InputProps) {
  const { palette, type, radius } = useTheme();
  const [focused, setFocused] = useState(false);
  const [hidden, setHidden] = useState(!!secure);

  return (
    <View style={style}>
      <Text style={[type.caption(palette.textSecondary), styles.label]}>{label}</Text>
      <View
        style={[
          styles.field,
          {
            backgroundColor: palette.surface,
            borderColor: error ? palette.danger : focused ? palette.teal : palette.border,
            shadowColor: focused ? palette.teal : 'transparent',
            borderRadius: radius.md,
          },
          focused && { borderWidth: 2 },
          multiline && { minHeight: 110, paddingTop: 14, paddingBottom: 14 },
        ]}
      >
        <TextInput
          placeholderTextColor={palette.textMuted}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          secureTextEntry={hidden}
          multiline={multiline}
          textAlignVertical={multiline ? 'top' : 'center'}
          style={[type.body(palette.text), styles.input]}
          {...rest}
        />
        {secure && (
          <PressableScale
            haptic="light"
            onPress={() => setHidden((h) => !h)}
            style={styles.eye}
            hitSlop={8}
          >
            {hidden ? (
              <Eye size={20} color={palette.textMuted} strokeWidth={1.75} />
            ) : (
              <EyeOff size={20} color={palette.textMuted} strokeWidth={1.75} />
            )}
          </PressableScale>
        )}
      </View>
      {error ? (
        <Text style={[type.bodySmall(palette.danger), styles.hint]}>{error}</Text>
      ) : hint ? (
        <Text style={[type.bodySmall(palette.textMuted), styles.hint]}>{hint}</Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  label: { marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.8, fontSize: 11 },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    paddingHorizontal: 16,
    minHeight: 54,
  },
  input: { flex: 1, paddingVertical: Platform.select({ ios: 16, default: 12 }) },
  eye: { padding: 4 },
  hint: { marginTop: 6 },
});
