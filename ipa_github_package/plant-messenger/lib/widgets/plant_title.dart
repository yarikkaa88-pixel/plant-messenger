import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/plant_colors.dart';

class PlantTitle extends StatelessWidget {
  const PlantTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'PLANT',
      style: GoogleFonts.playfairDisplay(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: PlantColors.darkGreen,
        letterSpacing: 2,
      ),
    );
  }
}

class PlantSubtitle extends StatelessWidget {
  const PlantSubtitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: PlantColors.darkGreen,
          height: 1.35,
        ),
      ),
    );
  }
}
