import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'prediction_step_layout.dart';
import 'scan_tips_sheet.dart';

class ScanPhotoStep extends StatelessWidget {
  const ScanPhotoStep({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onBack,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return PredictionStepLayout(
      title: "Let's get started!",
      subtitle:
          "Upload a cute pic of your cat's face.\n"
          'Make sure we can see their adorable\nfeatures nice and clear!',
      illustration: SvgPicture.asset('assets/images/breed_illustration.svg'),
      onBack: onBack,
      trailing: ScanTipsButton(
        onTap: () => showScanTipsSheet(
          context,
          type: ScanTipsType.photo,
        ),
      ),
      actions: [
        Button(
          label: 'Take Photo',
          icon: Icons.camera_alt_outlined,
          backgroundColor: brand.pink,
          onPressed: onCamera,
          semanticLabel: 'Take a photo of your cat',
        ),
        Button(
          label: 'Choose from Gallery',
          icon: Icons.photo_library_outlined,
          backgroundColor: brand.purple,
          onPressed: onGallery,
          semanticLabel: 'Choose a photo from gallery',
        ),
      ],
    );
  }
}
