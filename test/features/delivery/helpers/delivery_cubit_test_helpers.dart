import 'dart:io';

import 'package:gaseel_courier/features/orders/domain/models/order_checklist_question.dart';
import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';

/// Creates a temporary proof photo file for [DeliveryCompletionCubit] tests.
Future<String> createTempProofPhoto({
  String extension = 'jpg',
  int byteLength = 128,
}) async {
  final directory = Directory.systemTemp.createTempSync('delivery_cubit_test');
  final file = File('${directory.path}/proof.$extension');
  await file.writeAsBytes(List.filled(byteLength, 0));
  return file.path;
}

ProofPhotoUploadResult sampleUploadResult({
  String orderId = '42',
  String filePath = '/tmp/proof.jpg',
}) {
  return ProofPhotoUploadResult(
    id: 1,
    orderId: int.parse(orderId),
    photoType: ProofPhotoType.deliveryProof,
    filePath: filePath,
    uploadedAt: DateTime.utc(2026, 1, 15, 12, 0),
  );
}

List<OrderChecklistQuestion> sampleChecklistQuestions({
  bool withAnswers = false,
}) {
  return [
    OrderChecklistQuestion(
      questionId: 1,
      textEn: 'Was the customer reachable?',
      textAr: 'هل كان العميل متاحاً؟',
      displayOrder: 1,
      answer: withAnswers ? true : null,
    ),
    OrderChecklistQuestion(
      questionId: 2,
      textEn: 'Did you wait at the door?',
      textAr: 'هل انتظرت عند الباب؟',
      displayOrder: 2,
      answer: withAnswers ? false : null,
    ),
  ];
}
