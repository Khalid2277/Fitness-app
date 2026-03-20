import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/nutrition/providers/food_search_providers.dart';

/// Full-screen barcode scanner that looks up scanned codes via the food search
/// service and pops with a [FoodSearchResult] when a product is found.
class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(foodSearchServiceProvider);
      final result = await service.getFoodByBarcode(rawValue);

      if (!mounted) return;

      if (result != null) {
        context.pop(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product not found'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        // Allow user to try again after a brief delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error looking up barcode: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final scanWindowSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // ── Camera feed ──────────────────────────────────────────────────
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // ── Semi-transparent overlay with scan window ────────────────────
          _ScanOverlay(
            scanWindowSize: scanWindowSize,
          ),

          // ── Bottom instructions ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing) ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Looking up product...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 28,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Scan Barcode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Point your camera at a food barcode',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Scan overlay — dark border with transparent scan window
// ═══════════════════════════════════════════════════════════════════════════════

class _ScanOverlay extends StatelessWidget {
  final double scanWindowSize;

  const _ScanOverlay({required this.scanWindowSize});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _ScanOverlayPainter(
        scanWindowSize: scanWindowSize,
        borderColor: AppColors.primaryBlue,
        overlayColor: Colors.black.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double scanWindowSize;
  final Color borderColor;
  final Color overlayColor;

  _ScanOverlayPainter({
    required this.scanWindowSize,
    required this.borderColor,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanWindowSize,
      height: scanWindowSize,
    );
    final borderRadius = 16.0;

    // Draw semi-transparent overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = overlayColor,
    );

    // Draw corner brackets
    final bracketLength = 30.0;
    final bracketPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius));

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left, rrect.top + bracketLength)
        ..lineTo(rrect.left, rrect.top + borderRadius)
        ..arcToPoint(
          Offset(rrect.left + borderRadius, rrect.top),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(rrect.left + bracketLength, rrect.top),
      bracketPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right - bracketLength, rrect.top)
        ..lineTo(rrect.right - borderRadius, rrect.top)
        ..arcToPoint(
          Offset(rrect.right, rrect.top + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(rrect.right, rrect.top + bracketLength),
      bracketPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right, rrect.bottom - bracketLength)
        ..lineTo(rrect.right, rrect.bottom - borderRadius)
        ..arcToPoint(
          Offset(rrect.right - borderRadius, rrect.bottom),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(rrect.right - bracketLength, rrect.bottom),
      bracketPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left + bracketLength, rrect.bottom)
        ..lineTo(rrect.left + borderRadius, rrect.bottom)
        ..arcToPoint(
          Offset(rrect.left, rrect.bottom - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(rrect.left, rrect.bottom - bracketLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
