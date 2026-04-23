import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gym_coach/features/exercises/domain/exercise.dart';

/// Renders [Exercise.imageAssetPath] as SVG or raster depending on extension.
class ExerciseIllustration extends StatelessWidget {
  const ExerciseIllustration({
    super.key,
    required this.exercise,
    this.height = 180,
    this.fit = BoxFit.contain,
  });

  final Exercise exercise;
  final double height;
  final BoxFit fit;

  Widget _fallback(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: Colors.grey.shade200,
        child: Icon(Icons.accessibility_new, size: 40, color: Colors.grey.shade600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = exercise.imageAssetPath;
    if (path.toLowerCase().endsWith('.svg')) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: SvgPicture.asset(
          path,
          fit: fit,
          placeholderBuilder: (_) => _fallback(context),
        ),
      );
    }
    return Image.asset(
      path,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }
}
