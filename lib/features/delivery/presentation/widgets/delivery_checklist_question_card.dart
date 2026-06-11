import 'package:flutter/material.dart';

import 'delivery_checklist_answer_choice.dart';

/// Checklist question card with yes/no choices on [DeliveryToCustomerPage].
class DeliveryChecklistQuestionCard extends StatelessWidget {
  const DeliveryChecklistQuestionCard({
    super.key,
    required this.questionNumber,
    required this.questionText,
    required this.answer,
    required this.yesLabel,
    required this.noLabel,
    this.onChanged,
  });

  final int questionNumber;
  final String questionText;
  final bool? answer;
  final String yesLabel;
  final String noLabel;
  final ValueChanged<bool>? onChanged;

  static const Color _primary = Color(0xFF23C1B2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$questionNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DeliveryChecklistAnswerChoice(
                  label: yesLabel,
                  selected: answer == true,
                  onTap: onChanged == null ? null : () => onChanged!(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DeliveryChecklistAnswerChoice(
                  label: noLabel,
                  selected: answer == false,
                  onTap: onChanged == null ? null : () => onChanged!(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
