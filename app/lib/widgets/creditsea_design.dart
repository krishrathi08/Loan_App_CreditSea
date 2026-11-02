import 'package:flutter/material.dart';
import '../core/constants.dart';

class CreditSeaLogo extends StatelessWidget {
  final bool onBlue;
  final double size;

  const CreditSeaLogo({super.key, this.onBlue = false, this.size = 25});

  @override
  Widget build(BuildContext context) {
    final foreground = onBlue ? Colors.white : AppConst.navy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.waves_rounded, size: size + 4, color: AppConst.teal),
        const SizedBox(width: 5),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Credit',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              TextSpan(
                text: 'Sea',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: foreground,
                ),
              ),
            ],
          ),
          style: TextStyle(fontSize: size, letterSpacing: -.5),
        ),
      ],
    );
  }
}

class ApplicationProgress extends StatelessWidget {
  final int activeStep;

  const ApplicationProgress({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Register', 'Offer', 'Approval'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index == activeStep;
        final done = index < activeStep;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: active || done
                    ? AppConst.primary
                    : const Color(0xFFF0F2F5),
                child: done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: active ? Colors.white : Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                labels[index],
                style: TextStyle(
                  color: active ? AppConst.primary : Colors.black54,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFFE5E8ED),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
