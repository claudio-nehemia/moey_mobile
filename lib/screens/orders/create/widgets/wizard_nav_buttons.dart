import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';

class WizardNavButtons extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const WizardNavButtons({
    super.key,
    required this.currentStep,
    required this.isSubmitting,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == 3;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Constants.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentStep > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: onPrev,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Constants.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Sebelumnya', style: TextStyle(color: Constants.textMedium, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : (isLastStep ? onSubmit : onNext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Constants.primaryColor.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isLastStep ? 'Simpan Order' : 'Lanjutkan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
