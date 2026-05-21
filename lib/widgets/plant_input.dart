import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/plant_colors.dart';

class PlantInput extends StatelessWidget {
  const PlantInput({
    super.key,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
  });

  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.nunito(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: PlantColors.inputBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: PlantColors.darkGreen, width: 2.5),
        ),
      ),
    );
  }
}
