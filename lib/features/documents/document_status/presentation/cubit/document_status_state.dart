import 'package:equatable/equatable.dart';
import 'package:goapp/features/documents/document_status/domain/repositories/document_status_repository.dart';

sealed class DocumentStatusState extends Equatable {
  const DocumentStatusState();

  @override
  List<Object?> get props => const <Object?>[];
}

class DocumentStatusInitial extends DocumentStatusState {
  const DocumentStatusInitial();
}

class DocumentStatusLoading extends DocumentStatusState {
  const DocumentStatusLoading();
}

class DocumentStatusLoaded extends DocumentStatusState {
  const DocumentStatusLoaded(this.summary);

  final DocumentStatusSummary summary;

  bool get isEmpty => summary.items.isEmpty;

  @override
  List<Object?> get props => <Object?>[summary];
}

class DocumentStatusError extends DocumentStatusState {
  const DocumentStatusError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
