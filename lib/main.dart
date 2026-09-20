import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'logic/member_controller.dart';
import 'ui/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CaporalesApp(controller: MemberController()));
}

/// Raiz de la aplicacion: tema oscuro "Nobleza Caporal"
/// (negro profundo, dorado noble y rojo pasion).
class CaporalesApp extends StatefulWidget {
  const CaporalesApp({super.key, required this.controller});

  final MemberController controller;

  @override
  State<CaporalesApp> createState() => _CaporalesAppState();
}

class _CaporalesAppState extends State<CaporalesApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nobleza Caporal',
      debugShowCheckedModeBanner: false,
      theme: _buildTemaOscuro(),
      darkTheme: _buildTemaOscuro(),
      themeMode: ThemeMode.dark, // Modo oscuro predeterminado
      home: SplashScreen(controller: widget.controller),
    );
  }

  /// Tema oscuro con la identidad "Nobleza Caporal".
  ThemeData _buildTemaOscuro() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),

      // ===== AppBar =====
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xE60C0C0C),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(
          size: 28,
          color: AppColors.textPrimary,
        ),
        titleTextStyle: GoogleFonts.cinzelTextTheme().bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
      ),

      // ===== Tarjetas =====
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ===== Barra de navegacion (iconos grandes, activo dorado) =====
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF151515),
        indicatorColor: AppColors.gold.withValues(alpha: 0.22),
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.gold : AppColors.textSecondary,
            size: 30,
          );
        }),
      ),

      // ===== Botones (CTA en Rojo Pasion) =====
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ===== Inputs =====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        prefixIconColor: AppColors.goldLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),

      // ===== SnackBars =====
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ===== BottomSheet =====
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),

      // ===== Divisores =====
      dividerTheme: DividerThemeData(
        color: AppColors.border.withValues(alpha: 0.6),
        thickness: 1,
      ),
    );
  }
}
