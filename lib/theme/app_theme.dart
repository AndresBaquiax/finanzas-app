import 'package:flutter/material.dart';
import '../widgets/app_animations.dart';

class AppTheme {
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: AppPageTransitionsBuilder(),
      TargetPlatform.iOS: AppPageTransitionsBuilder(),
      TargetPlatform.windows: AppPageTransitionsBuilder(),
      TargetPlatform.macOS: AppPageTransitionsBuilder(),
      TargetPlatform.linux: AppPageTransitionsBuilder(),
      TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
    },
  );

  static final RoundedRectangleBorder _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static const TextStyle _buttonText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static const Color primarySolid = Color(0xFF1D4ED8);
  static const Color primaryDarkSolid = Color(0xFF0F172A);

  static const Color incomeSolid = Color(0xFF059669);
  static const Color incomeSoftBg = Color(0xFFECFDF5);

  static const Color expenseSolid = Color(0xFFDC2626);
  static const Color expenseSoftBg = Color(0xFFFEF2F2);

  static const Color warningSolid = Color(0xFFD97706);
  static const Color warningSoftBg = Color(0xFFFFFBEB);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF263244);
  static const Color controlBorderDark = Color(0xFF3A4A60);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color bgDark = Color(0xFF090D16);

  static const List<int> accountSolidColors = [
    0xFF1E293B,
    0xFF1D4ED8,
    0xFF0F766E,
    0xFF15803D,
    0xFF6D28D9,
    0xFFB91C1C,
    0xFFC2410C,
    0xFF0369A1,
    0xFF4338CA,
    0xFF374151,
  ];

  static const List<String> accountEmojis = [
    '💳',
    '🏦',
    '🐷',
    '💵',
    '💎',
    '💰',
    '🪙',
    '🏧',
    '📈',
    '🛡️',
    '🏠',
    '🚗',
    '✈️',
    '🎓',
  ];

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      visualDensity: VisualDensity.compact,
      pageTransitionsTheme: _pageTransitions,
      extensions: const [AppPalette.light],
      colorScheme: const ColorScheme.light(
        primary: primarySolid,
        onPrimary: Colors.white,
        secondary: primaryDarkSolid,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: textPrimaryLight,
        error: expenseSolid,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: _buttonShape,
          textStyle: _buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _buttonShape,
          textStyle: _buttonText,
          foregroundColor: textPrimaryLight,
          side: const BorderSide(color: borderLight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: _buttonShape,
          textStyle: _buttonText,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDarkSolid,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: borderLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        backgroundColor: surfaceLight,
        showCheckmark: false,
        side: const BorderSide(color: borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        labelStyle: const TextStyle(
          color: textSecondaryLight,
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primarySolid, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: primarySolid.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? primarySolid
                : textSecondaryLight,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primarySolid : textSecondaryLight,
          );
        }),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      visualDensity: VisualDensity.compact,
      pageTransitionsTheme: _pageTransitions,
      extensions: const [AppPalette.dark],
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        onPrimary: Colors.white,
        secondary: surfaceDark,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF2563EB),
        onSecondaryContainer: Colors.white,
        outline: controlBorderDark,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        error: Color(0xFFF87171),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: _buttonShape,
          textStyle: _buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _buttonShape,
          textStyle: _buttonText,
          foregroundColor: textPrimaryDark,
          side: const BorderSide(color: controlBorderDark),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: _buttonShape,
          textStyle: _buttonText,
          foregroundColor: const Color(0xFF60A5FA),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          color: textPrimaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFF334155),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderDark),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        backgroundColor: surfaceDark,
        showCheckmark: false,
        side: const BorderSide(color: controlBorderDark),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF0B0F19),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        labelStyle: const TextStyle(
          color: textSecondaryDark,
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF60A5FA)
                : textSecondaryDark,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF60A5FA) : textSecondaryDark,
          );
        }),
      ),
    );
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color accent;
  final Color accentFill;
  final Color income;
  final Color incomeSoftBg;
  final Color onIncomeSoft;
  final Color incomeDivider;
  final Color expense;
  final Color expenseSoftBg;
  final Color warning;
  final Color warningSoftBg;
  final Color track;
  final Color textMuted;
  final Color iconMuted;
  final Color heroBg;
  final Color outline;

  const AppPalette({
    required this.accent,
    required this.accentFill,
    required this.income,
    required this.incomeSoftBg,
    required this.onIncomeSoft,
    required this.incomeDivider,
    required this.expense,
    required this.expenseSoftBg,
    required this.warning,
    required this.warningSoftBg,
    required this.track,
    required this.textMuted,
    required this.iconMuted,
    required this.heroBg,
    required this.outline,
  });

  static const AppPalette light = AppPalette(
    accent: AppTheme.primarySolid,
    accentFill: AppTheme.primarySolid,
    income: AppTheme.incomeSolid,
    incomeSoftBg: AppTheme.incomeSoftBg,
    onIncomeSoft: Color(0xFF065F46),
    incomeDivider: Color(0xFFA7F3D0),
    expense: AppTheme.expenseSolid,
    expenseSoftBg: AppTheme.expenseSoftBg,
    warning: AppTheme.warningSolid,
    warningSoftBg: AppTheme.warningSoftBg,
    track: Color(0xFFE2E8F0),
    textMuted: Color(0xFF64748B),
    iconMuted: Color(0xFF94A3B8),
    heroBg: AppTheme.primaryDarkSolid,
    outline: Color(0xFFCBD5E1),
  );

  static const AppPalette dark = AppPalette(
    accent: Color(0xFF60A5FA),
    accentFill: Color(0xFF2563EB),
    income: Color(0xFF34D399),
    incomeSoftBg: Color(0x2934D399),
    onIncomeSoft: Color(0xFFA7F3D0),
    incomeDivider: Color(0x5934D399),
    expense: Color(0xFFF87171),
    expenseSoftBg: Color(0x29F87171),
    warning: Color(0xFFFBBF24),
    warningSoftBg: Color(0x24FBBF24),
    track: Color(0xFF334155),
    textMuted: Color(0xFF94A3B8),
    iconMuted: Color(0xFF94A3B8),
    heroBg: Color(0xFF1E293B),
    outline: Color(0xFF475569),
  );

  @override
  AppPalette copyWith({
    Color? accent,
    Color? accentFill,
    Color? income,
    Color? incomeSoftBg,
    Color? onIncomeSoft,
    Color? incomeDivider,
    Color? expense,
    Color? expenseSoftBg,
    Color? warning,
    Color? warningSoftBg,
    Color? track,
    Color? textMuted,
    Color? iconMuted,
    Color? heroBg,
    Color? outline,
  }) {
    return AppPalette(
      accent: accent ?? this.accent,
      accentFill: accentFill ?? this.accentFill,
      income: income ?? this.income,
      incomeSoftBg: incomeSoftBg ?? this.incomeSoftBg,
      onIncomeSoft: onIncomeSoft ?? this.onIncomeSoft,
      incomeDivider: incomeDivider ?? this.incomeDivider,
      expense: expense ?? this.expense,
      expenseSoftBg: expenseSoftBg ?? this.expenseSoftBg,
      warning: warning ?? this.warning,
      warningSoftBg: warningSoftBg ?? this.warningSoftBg,
      track: track ?? this.track,
      textMuted: textMuted ?? this.textMuted,
      iconMuted: iconMuted ?? this.iconMuted,
      heroBg: heroBg ?? this.heroBg,
      outline: outline ?? this.outline,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeSoftBg: Color.lerp(incomeSoftBg, other.incomeSoftBg, t)!,
      onIncomeSoft: Color.lerp(onIncomeSoft, other.onIncomeSoft, t)!,
      incomeDivider: Color.lerp(incomeDivider, other.incomeDivider, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoftBg: Color.lerp(expenseSoftBg, other.expenseSoftBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoftBg: Color.lerp(warningSoftBg, other.warningSoftBg, t)!,
      track: Color.lerp(track, other.track, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      heroBg: Color.lerp(heroBg, other.heroBg, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
