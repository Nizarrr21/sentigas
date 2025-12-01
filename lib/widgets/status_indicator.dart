import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: statusInfo['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (statusInfo['color'] as Color).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusInfo['icon'] as IconData,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Sistem',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusInfo['message'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'BAHAYA':
        return {
          'color': const Color(0xFFE74C3C),
          'gradient': [
            const Color(0xFFE74C3C).withOpacity(0.8),
            const Color(0xFFC0392B),
          ],
          'icon': Icons.warning_amber_rounded,
          'message': 'Kadar gas berbahaya! Kipas beroperasi maksimal',
        };
      case 'WASPADA':
        return {
          'color': const Color(0xFFF39C12),
          'gradient': [
            const Color(0xFFF39C12).withOpacity(0.8),
            const Color(0xFFE67E22),
          ],
          'icon': Icons.error_outline,
          'message': 'Kadar gas meningkat. Harap waspada',
        };
      case 'PANAS':
        return {
          'color': const Color(0xFFE67E22),
          'gradient': [
            const Color(0xFFE67E22).withOpacity(0.8),
            const Color(0xFFD35400),
          ],
          'icon': Icons.local_fire_department,
          'message': 'Suhu tinggi terdeteksi',
        };
      default: // AMAN
        return {
          'color': const Color(0xFF27AE60),
          'gradient': [
            const Color(0xFF27AE60).withOpacity(0.8),
            const Color(0xFF229954),
          ],
          'icon': Icons.check_circle_outline,
          'message': 'Semua sensor dalam kondisi normal',
        };
    }
  }
}
