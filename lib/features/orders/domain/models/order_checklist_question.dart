class OrderChecklistQuestion {
  const OrderChecklistQuestion({
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

  OrderChecklistQuestion copyWith({
    bool? answer,
    bool clearAnswer = false,
  }) {
    return OrderChecklistQuestion(
      questionId: questionId,
      textEn: textEn,
      textAr: textAr,
      displayOrder: displayOrder,
      answer: clearAnswer ? null : answer ?? this.answer,
    );
  }
}
