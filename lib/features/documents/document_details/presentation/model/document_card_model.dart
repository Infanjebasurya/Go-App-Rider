import 'package:equatable/equatable.dart';

class DocumentCardModel extends Equatable {
  const DocumentCardModel({
    required this.title,
    required this.numberMasked,
    required this.status,
    required this.imageUrl,
    required this.uploadedDate,
  });

  final String title;
  final String numberMasked;
  final String status;
  final String imageUrl;
  final String uploadedDate;

  @override
  List<Object?> get props => <Object?>[
    title,
    numberMasked,
    status,
    imageUrl,
    uploadedDate,
  ];
}
