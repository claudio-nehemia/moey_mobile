import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';

class OrderPipelineStepper extends StatelessWidget {
  final String? currentPhase;

  const OrderPipelineStepper({super.key, this.currentPhase});

  @override
  Widget build(BuildContext context) {
    final phases = ['survey', 'moodboard', 'rab_internal', 'kontrak'];
    final phaseLabels = ['Survey', 'Desain', 'RAB', 'Kontrak'];

    int activeIndex = 0;
    final normalized = (currentPhase ?? 'survey').toLowerCase();
    if (normalized.contains('survey')) {
      activeIndex = 0;
    } else if (normalized.contains('moodboard') || normalized.contains('desain')) {
      activeIndex = 1;
    } else if (normalized.contains('rab') || normalized.contains('estimasi')) {
      activeIndex = 2;
    } else if (normalized.contains('kontrak') || normalized.contains('selesai')) {
      activeIndex = 3;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(phases.length, (index) {
          final isCompleted = index < activeIndex;
          final isActive = index == activeIndex;
          final color = isCompleted
              ? Constants.successColor
              : isActive
                  ? Constants.primaryColor
                  : Constants.textLight.withOpacity(0.4);

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : (isCompleted || isActive)
                                ? Constants.successColor
                                : Constants.borderColor,
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: isActive ? 6 : 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Constants.primaryColor.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == phases.length - 1
                            ? Colors.transparent
                            : isCompleted
                                ? Constants.successColor
                                : Constants.borderColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  phaseLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? Constants.textDark : Constants.textMedium.withOpacity(0.8),
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
