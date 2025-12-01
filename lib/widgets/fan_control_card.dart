import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class FanControlCard extends StatefulWidget {
  final int fanSpeed;
  final bool isManual;
  final Function(int) onSpeedChanged;
  final Function(bool) onModeChanged;

  const FanControlCard({
    super.key,
    required this.fanSpeed,
    required this.isManual,
    required this.onSpeedChanged,
    required this.onModeChanged,
  });

  @override
  State<FanControlCard> createState() => _FanControlCardState();
}

class _FanControlCardState extends State<FanControlCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _updateRotation();
    _sliderValue = widget.fanSpeed.toDouble();
  }

  @override
  void didUpdateWidget(FanControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fanSpeed != widget.fanSpeed) {
      _updateRotation();
      if (!widget.isManual) {
        setState(() {
          _sliderValue = widget.fanSpeed.toDouble();
        });
      }
    }
  }

  void _updateRotation() {
    if (widget.fanSpeed > 0) {
      final speed = 2000 / (widget.fanSpeed / 255 * 4 + 1);
      _rotationController.duration = Duration(milliseconds: speed.toInt());
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.air, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fan Control',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.isManual ? 'Manual Mode' : 'Auto Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Mode Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildModeButton('Auto', !widget.isManual, () {
                      widget.onModeChanged(false);
                    }),
                    _buildModeButton('Manual', widget.isManual, () {
                      widget.onModeChanged(true);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Fan Animation
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
                // Rotating fan blades
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: child,
                    );
                  },
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: FanPainter(speedPercent: widget.fanSpeed / 255),
                  ),
                ),
                // Center circle with speed
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(widget.fanSpeed / 255 * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                      Text(
                        widget.fanSpeed.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Slider (only active in manual mode)
          if (widget.isManual) ...[
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _sliderValue,
                      min: 0,
                      max: 255,
                      divisions: 51,
                      label: _sliderValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                      onChangeEnd: (value) {
                        widget.onSpeedChanged(value.round());
                      },
                    ),
                  ),
                ),
                Text(
                  '${(_sliderValue / 255 * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fan speed is controlled automatically',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF667EEA) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class FanPainter extends CustomPainter {
  final double speedPercent;

  FanPainter({required this.speedPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 4 fan blades
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * math.pi / 180;
      final path = Path();

      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + radius * 0.3 * math.cos(angle - 0.3),
        center.dy + radius * 0.3 * math.sin(angle - 0.3),
      );
      path.quadraticBezierTo(
        center.dx + radius * 0.7 * math.cos(angle),
        center.dy + radius * 0.7 * math.sin(angle),
        center.dx + radius * 0.3 * math.cos(angle + 0.3),
        center.dy + radius * 0.3 * math.sin(angle + 0.3),
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FanPainter oldDelegate) => false;
}
