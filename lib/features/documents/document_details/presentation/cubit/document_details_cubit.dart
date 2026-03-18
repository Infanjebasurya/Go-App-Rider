import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/documents/document_details/domain/repositories/document_details_repository.dart';
import 'package:goapp/features/documents/document_details/presentation/cubit/document_details_state.dart';

class DocumentDetailsCubit extends Cubit<DocumentDetailsState> {
  DocumentDetailsCubit({required DocumentDetailsRepository repository})
    : _repository = repository,
      super(const DocumentDetailsInitial());

  final DocumentDetailsRepository _repository;

  void _log(String message) {
    developer.log(message, name: 'DocumentDetails');
  }

  Future<void> load() async {
    emit(const DocumentDetailsLoading());
    try {
      final results = await Future.wait([
        _repository.getAadhaarCard(),
        _repository.getPanCard(),
      ]);
      emit(DocumentDetailsLoaded(aadhaar: results[0], pan: results[1]));
    } catch (e) {
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');
      _log('Document details error <- $msg');
      emit(
        DocumentDetailsError(
          message: msg.isEmpty ? 'Failed to load documents.' : msg,
        ),
      );
    }
  }
}
