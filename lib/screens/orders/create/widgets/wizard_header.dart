import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';

class WizardHeader extends StatelessWidget {
  final int currentStep;

  const WizardHeader({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final stepLabels = ['Klien', 'Alamat', 'Parameter', 'Tim & File'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;
          final color = isCompleted
              ? Constants.successColor
              : isActive
                  ? Constants.primaryColor
                  : Constants.textLight.withOpacity(0.4);

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : color,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: isActive ? 6 : 1.5),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabels[index],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? Constants.textDark : Constants.textMedium,
                      ),
                    ),
                  ],
                ),
                if (index < 3)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        height: 2,
                        color: isCompleted ? Constants.successColor : Constants.borderColor,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
