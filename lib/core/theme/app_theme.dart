import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const electricBlue = Color(0xFF007AFF);
  static const vibrantPurple = Color(0xFFAF52DE);
  static const emeraldGreen = Color(0xFF10B981);
  static const brightTeal = Color(0xFF14B8A6);
  static const warmAmber = Color(0xFFF59E0B);
  static const warmOrange = Color(0xFFF97316);
  static const crimsonRed = Color(0xFFB91C1C);
  static const coralRose = Color(0xFFFB7185);
  static const deepIndigo = Color(0xFF312E81);
  static const orchidViolet = Color(0xFFC084FC);
  static const deepMaroon = Color(0xFF7F1D1D);
  static const cyberInk = Color(0xFF101828);
  static const coolMist = Color(0xFFF4F7FF);
  static const slateMuted = Color(0xFF64748B);
  static const deepSpace = Color(0xFF080B1A);
  static const nightPanel = Color(0xFF111827);
  static const richBronze = warmAmber;
  static const warmSand = coolMist;
  static const espresso = cyberInk;
  static const sepia = slateMuted;
  static const deepTeal = brightTeal;
  static const emerald = emeraldGreen;
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

  static CampusPalette campusPalette(String campusName) {
    final normalized = campusName.toLowerCase();
    if (normalized.contains('rektorat') || normalized.contains('rektor')) {
      return const CampusPalette(
        primary: electricBlue,
        secondary: vibrantPurple,
        tertiary: Color(0xFF22D3EE),
        darkSurface: deepSpace,
        gradient: cyberGradient,
      );
    }
    if (normalized.contains('kampus 1')) {
      return const CampusPalette(
        primary: emeraldGreen,
        secondary: brightTeal,
        tertiary: Color(0xFF22D3EE),
        darkSurface: Color(0xFF061A17),
        gradient: LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    if (normalized.contains('kampus 2')) {
      return const CampusPalette(
        primary: warmAmber,
        secondary: warmOrange,
        tertiary: Color(0xFFF97316),
        darkSurface: Color(0xFF1F1300),
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    if (normalized.contains('kampus 3')) {
      return const CampusPalette(
        primary: crimsonRed,
        secondary: coralRose,
        tertiary: Color(0xFFF43F5E),
        darkSurface: Color(0xFF1F0A0A),
        gradient: LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFE11D48), Color(0xFFFB7185)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    if (normalized.contains('kampus 4')) {
      return const CampusPalette(
        primary: deepIndigo,
        secondary: orchidViolet,
        tertiary: Color(0xFFA78BFA),
        darkSurface: Color(0xFF111033),
        gradient: LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF7C3AED), Color(0xFFC084FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    return const CampusPalette(
      primary: electricBlue,
      secondary: vibrantPurple,
      tertiary: Color(0xFF22D3EE),
      darkSurface: deepSpace,
      gradient: cyberGradient,
    );
  }

  static ThemeData campusTheme(ThemeData base, String campusName) {
    final palette = campusPalette(campusName);
    final dark = base.brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: base.brightness,
      primary: palette.primary,
      secondary: palette.secondary,
      tertiary: palette.tertiary,
      surface: dark ? const Color(0xFF111827) : Colors.white,
      error: dark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
    );
    return base.copyWith(
      extensions: [
        CampusThemeExtension(
          primary: palette.primary,
          secondary: palette.secondary,
          tertiary: palette.tertiary,
          gradient: palette.gradient,
        ),
      ],
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? palette.darkSurface : coolMist,
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStatePropertyAll(palette.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(
            base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStatePropertyAll(palette.secondary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(
            base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  static CampusThemeExtension campusColorsOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).extension<CampusThemeExtension>() ??
        CampusThemeExtension(
          primary: scheme.primary,
          secondary: scheme.secondary,
          tertiary: scheme.tertiary,
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
  }

  static LinearGradient campusGradientOf(BuildContext context) {
    return campusColorsOf(context).gradient;
  }

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
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.bold),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.bold),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.bold),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
      fontFamily: GoogleFonts.poppins().fontFamily,
      fontFamilyFallback: const ['Tahoma', 'Arial', 'sans-serif'],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: offWhite,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
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

  static ThemeData get darkTheme => dark;

  static ThemeData get dark {
    final textTheme = _buildTextTheme(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: vibrantPurple,
      brightness: Brightness.dark,
      primary: electricBlue,
      secondary: vibrantPurple,
      tertiary: const Color(0xFF22D3EE),
      surface: const Color(0xFF141827),
      error: const Color(0xFFF87171),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF070A16),
      fontFamily: GoogleFonts.poppins().fontFamily,
      fontFamilyFallback: const ['Tahoma', 'Arial', 'sans-serif'],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF070A16),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF141827),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF29324A)),
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
        fillColor: const Color(0xFF111827),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF29324A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF29324A)),
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

class CampusPalette {
  const CampusPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.darkSurface,
    required this.gradient,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color darkSurface;
  final LinearGradient gradient;
}

class CampusThemeExtension extends ThemeExtension<CampusThemeExtension> {
  const CampusThemeExtension({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.gradient,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final LinearGradient gradient;

  @override
  CampusThemeExtension copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    LinearGradient? gradient,
  }) {
    return CampusThemeExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      gradient: gradient ?? this.gradient,
    );
  }

  @override
  CampusThemeExtension lerp(
    ThemeExtension<CampusThemeExtension>? other,
    double t,
  ) {
    if (other is! CampusThemeExtension) {
      return this;
    }
    return CampusThemeExtension(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      tertiary: Color.lerp(tertiary, other.tertiary, t) ?? tertiary,
      gradient: LinearGradient(
        colors: [
          Color.lerp(primary, other.primary, t) ?? primary,
          Color.lerp(secondary, other.secondary, t) ?? secondary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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
      decoration: BoxDecoration(
        gradient: enabled
            ? AppTheme.campusGradientOf(context)
            : LinearGradient(
                colors: [
                  AppTheme.slateMuted.withValues(alpha: 0.45),
                  AppTheme.slateMuted.withValues(alpha: 0.30),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
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
