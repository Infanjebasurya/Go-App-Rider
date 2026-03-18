import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/documents/document_status/domain/repositories/document_status_repository.dart';
import 'package:goapp/features/documents/document_status/presentation/cubit/document_status_state.dart';

class DocumentStatusCubit extends Cubit<DocumentStatusState> {
  DocumentStatusCubit({required DocumentStatusRepository repository})
    : _repository = repository,
      super(const DocumentStatusInitial());

  final DocumentStatusRepository _repository;

  void _log(String message) {
    developer.log(message, name: 'DocumentStatus');
  }

  Future<void> load() async {
    emit(const DocumentStatusLoading());
    try {
      final summary = await _repository.getSummary();
      emit(DocumentStatusLoaded(summary));
    } catch (e) {
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');
      _log('Document status error <- $msg');
      emit(DocumentStatusError(msg.isEmpty ? 'Failed to load status.' : msg));
    }
  }
}
