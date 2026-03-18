import 'package:equatable/equatable.dart';
import 'package:goapp/features/documents/document_details/presentation/model/document_card_model.dart';

sealed class DocumentDetailsState extends Equatable {
  const DocumentDetailsState();

  @override
  List<Object?> get props => const <Object?>[];
}

class DocumentDetailsInitial extends DocumentDetailsState {
  const DocumentDetailsInitial();
}

class DocumentDetailsLoading extends DocumentDetailsState {
  const DocumentDetailsLoading();
}

class DocumentDetailsLoaded extends DocumentDetailsState {
  const DocumentDetailsLoaded({required this.aadhaar, required this.pan});

  final DocumentCardModel? aadhaar;
  final DocumentCardModel? pan;

  bool get isEmpty => aadhaar == null && pan == null;

  @override
  List<Object?> get props => <Object?>[aadhaar, pan];
}

class DocumentDetailsError extends DocumentDetailsState {
  const DocumentDetailsError({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
