import 'package:equatable/equatable.dart';

enum DocumentStatusItemType { profilePhoto, dl, rc, aadhaar, pan }

class DocumentStatusItemModel extends Equatable {
  const DocumentStatusItemModel({
    required this.type,
    required this.title,
    required this.status,
  });

  final DocumentStatusItemType type;
  final String title;
  final String status;

  @override
  List<Object?> get props => <Object?>[type, title, status];
}
