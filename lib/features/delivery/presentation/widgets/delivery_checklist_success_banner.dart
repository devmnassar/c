import 'package:flutter/material.dart';

/// Green success banner shown in the attempted-delivery checklist dialog.
class DeliveryChecklistSuccessBanner extends StatelessWidget {
  const DeliveryChecklistSuccessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final message = languageCode == 'ar'
        ? 'تم إرسال هذه القائمة. يمكنك الآن الضغط على Attempted Delivery.'
        : 'Checklist saved successfully. You can now press Attempted Delivery.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF059669),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF047857),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
