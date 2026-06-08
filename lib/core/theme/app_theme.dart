import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const electricBlue = Color(0xFF007AFF);
  static const vibrantPurple = Color(0xFFAF52DE);
  static const cyberInk = Color(0xFF101828);
  static const coolMist = Color(0xFFF4F7FF);
  static const slateMuted = Color(0xFF64748B);
  static const deepSpace = Color(0xFF080B1A);
  static const nightPanel = Color(0xFF111827);
  static const richBronze = vibrantPurple;
  static const warmSand = coolMist;
  static const espresso = cyberInk;
  static const sepia = slateMuted;
  static const deepTeal = electricBlue;
  static const emerald = vibrantPurple;
  static const cleanCyan = electricBlue;
  static const offWhite = coolMist;
  static const ink = cyberInk;
  static const muted = slateMuted;
  static const midnightNavy = deepSpace;
  static const darkCharcoal = nightPanel;

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [electricBlue, vibrantPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration cyberGradientButtonDecoration({
    double borderRadius = 16,
    bool enabled = true,
  }) {
    return BoxDecoration(
      gradient: enabled
          ? cyberGradient
          : LinearGradient(
              colors: [
                slateMuted.withValues(alpha: 0.45),
                slateMuted.withValues(alpha: 0.30),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: enabled
          ? [
              BoxShadow(
                color: electricBlue.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ]
          : null,
    );
  }

  static TextTheme _buildTextTheme({
    required Color bodyColor,
    required Color displayColor,
  }) {
    final base = GoogleFonts.poppinsTextTheme().apply(
      bodyColor: bodyColor,
      displayColor: displayColor,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: electricBlue,
      primary: electricBlue,
      secondary: vibrantPurple,
      tertiary: electricBlue,
      surface: Colors.white,
      error: const Color(0xFFEF4444),
    );

    final textTheme = _buildTextTheme(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: offWhite,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: offWhite,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        shadowColor: const Color(0x33007AFF),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          disabledBackgroundColor: slateMuted.withValues(alpha: 0.24),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: vibrantPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: electricBlue,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: electricBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: electricBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = _buildTextTheme(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: electricBlue,
      brightness: Brightness.dark,
      primary: electricBlue,
      secondary: vibrantPurple,
      tertiary: electricBlue,
      surface: darkCharcoal,
      error: const Color(0xFFF87171),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: midnightNavy,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: midnightNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCharcoal,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2B3A3A)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          disabledBackgroundColor: slateMuted.withValues(alpha: 0.24),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: vibrantPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: electricBlue,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: electricBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF242424),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A4A4A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A4A4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: electricBlue, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFB7C7C7),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF91A2A2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class CyberGradientButton extends StatelessWidget {
  const CyberGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 54,
    this.borderRadius = 16,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: AppTheme.cyberGradientButtonDecoration(
        borderRadius: borderRadius,
        enabled: enabled,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: Size.fromHeight(height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}
