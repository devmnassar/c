import '../../domain/models/order_checklist_question.dart';

class OrderChecklistQuestionModel {
  const OrderChecklistQuestionModel({
    required this.questionId,
    required this.textEn,
    required this.textAr,
    required this.displayOrder,
    this.answer,
  });

  final int questionId;
  final String textEn;
  final String textAr;
  final int displayOrder;
  final bool? answer;

  factory OrderChecklistQuestionModel.fromJson(Map<String, dynamic> json) {
    return OrderChecklistQuestionModel(
      questionId: (json['questionId'] as num?)?.toInt() ?? 0,
      textEn: (json['textEn'] as String? ?? '').trim(),
      textAr: (json['textAr'] as String? ?? '').trim(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      answer: json['answer'] as bool?,
    );
  }

  OrderChecklistQuestion toEntity() {
    return OrderChecklistQuestion(
      questionId: questionId,
      textEn: textEn,
      textAr: textAr,
      displayOrder: displayOrder,
      answer: answer,
    );
  }
}
