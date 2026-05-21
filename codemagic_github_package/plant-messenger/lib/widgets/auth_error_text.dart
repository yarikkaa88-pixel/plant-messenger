import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF8B1E1E).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B1E1E), width: 1.5),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: const Color(0xFF5C1010),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
