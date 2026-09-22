/// NoorIcons — the Noor Companion SVG icon set.
/// Every glyph is a 24px-grid, 1.75-stroke, round-capped line icon
/// (Lucide-style geometry) rendered inline via flutter_svg, so icons
/// stay crisp at any size and inherit colour through currentColor.
///
/// Usage: NoorIcons.home(size: 22, color: AppColors.ink)
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class NoorIcons {
  static const String _wrap =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="COLOR" stroke-width="1.75" '
      'stroke-linecap="round" stroke-linejoin="round">PATH</svg>';

  static Widget _icon(String path,
      {double size = 24, Color color = const Color(0xFF171930)}) {
    final svg = _wrap.replaceFirst('PATH', path).replaceFirst('COLOR', _hex(color));
    return SvgPicture.string(svg, width: size, height: size);
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  // ── Navigation ─────────────────────────────────────────────────────────────

  static Widget home({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h5v-6h4v6h5V9.5"/>',
          size: size, color: color);

  static Widget compass({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2 5-5 2 2-5z"/>',
          size: size, color: color);

  static Widget chart({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M22 20H2"/>',
          size: size, color: color);

  static Widget user({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<circle cx="12" cy="8" r="4"/><path d="M5 21c0-3.5 3-6 7-6s7 2.5 7 6"/>',
          size: size, color: color);

  // ── Core actions ───────────────────────────────────────────────────────────

  static Widget bell({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M18 9a6 6 0 1 0-12 0c0 5-2 6-2 6h16s-2-1-2-6"/><path d="M10.3 19a2 2 0 0 0 3.4 0"/>',
          size: size, color: color);

  static Widget search({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
          size: size, color: color);

  static Widget sliders({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M4 21v-7"/><path d="M4 10V3"/><path d="M12 21v-9"/><path d="M12 8V3"/><path d="M20 21v-5"/><path d="M20 12V3"/><path d="M2 14h4"/><path d="M10 8h4"/><path d="M18 16h4"/>',
          size: size, color: color);

  static Widget heart({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M19.5 12.6 12 20l-7.5-7.4A5 5 0 1 1 12 6.3a5 5 0 1 1 7.5 6.3Z"/>',
          size: size, color: color);

  static Widget phone({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 2 .7 2.8a2 2 0 0 1-.4 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2Z"/>',
          size: size, color: color);

  // ── Islamic content ────────────────────────────────────────────────────────

  static Widget bookOpen({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M2 4h6a4 4 0 0 1 4 4v13a3 3 0 0 0-3-3H2z"/><path d="M22 4h-6a4 4 0 0 0-4 4v13a3 3 0 0 1 3-3h7z"/>',
          size: size, color: color);

  static Widget moon({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M20 13.5A8.5 8.5 0 1 1 11.5 3a7 7 0 0 0 8.5 8.5Z"/>',
          size: size, color: color);

  static Widget flame({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M12 2s5.5 5 5.5 10.5a5.5 5.5 0 0 1-11 0c0-2.3 1.2-4.3 2.3-5.7 0 1.9.8 3.2 1.7 3.7C10.8 8.4 12 2 12 2Z"/><path d="M12 22a3.5 3.5 0 0 1-3.5-3.5c0-1.9 2-4 3.5-5.2 1.5 1.2 3.5 3.3 3.5 5.2A3.5 3.5 0 0 1 12 22Z"/>',
          size: size, color: color);

  static Widget play({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M7 4.5v15l12-7.5z"/>', size: size, color: color);

  static Widget sparkles({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M12 3v4"/><path d="M10 5h4"/><path d="m18.5 9.5 1 2.5 2.5 1-2.5 1-1 2.5-1-2.5L15 13l2.5-1z"/><path d="m5 13 1 2.5L8.5 17 6 18l-1 2.5L4 18l-2.5-1L4 15.5z"/>',
          size: size, color: color);

  static Widget shield({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M12 22s8-3.5 8-10V5l-8-3-8 3v7c0 6.5 8 10 8 10Z"/><path d="m9 11.5 2 2 4-4.5"/>',
          size: size, color: color);

  static Widget star({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
          size: size, color: color);

  // ── Controls ───────────────────────────────────────────────────────────────

  static Widget chevronLeft({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="m14.5 5.5-6.5 6.5 6.5 6.5"/>', size: size, color: color);

  static Widget chevronRight({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="m9.5 5.5 6.5 6.5-6.5 6.5"/>', size: size, color: color);

  static Widget check({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="m4.5 12.5 5 5 10-11"/>', size: size, color: color);

  static Widget close({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M6 6l12 12"/><path d="M18 6 6 18"/>', size: size, color: color);

  static Widget plus({double size = 24, Color color = const Color(0xFF171930)}) =>
      _icon('<path d="M12 5v14"/><path d="M5 12h14"/>', size: size, color: color);
}
