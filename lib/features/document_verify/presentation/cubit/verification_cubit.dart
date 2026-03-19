import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/storage/onboarding_submission_store.dart';
import 'package:goapp/features/document_verify/data/datasources/submit_all_documents_remote_data_source.dart';
import 'package:goapp/features/document_verify/presentation/cubit/verification_state.dart';

import '../model/document_model.dart';
import '../model/document_progress_store.dart';

class VerificationCubit extends Cubit<VerificationState> {
  VerificationCubit({
    required SubmitAllDocumentsRemoteDataSource submitAllDataSource,
  }) : _submitAllDataSource = submitAllDataSource,
       super(VerificationState.initial()) {
    syncFromStore();
  }

  final SubmitAllDocumentsRemoteDataSource _submitAllDataSource;

  void syncFromStore() {
    final profileImageUploaded = DocumentProgressStore.isProfileImageUploaded();
    final updatedDocs = state.documents.map((doc) {
      final completed = DocumentProgressStore.isCompleted(doc.type);
      return doc.copyWith(
        status: completed ? DocumentStatus.completed : DocumentStatus.required,
      );
    }).toList();
    emit(
      state.copyWith(
        documents: updatedDocs,
        isProfileImageUploaded: profileImageUploaded,
      ),
    );
  }

  void setDeclarationAccepted(bool value) {
    emit(state.copyWith(declarationAccepted: value, clearError: true));
  }

  Future<void> uploadDocument(DocumentType type) async {
    final updatedDocs = state.documents.map((doc) {
      if (doc.type == type) {
        return doc.copyWith(status: DocumentStatus.uploading);
      }
      return doc;
    }).toList();

    emit(state.copyWith(documents: updatedDocs, clearError: true));

    await Future.delayed(const Duration(seconds: 2));

    final completedDocs = state.documents.map((doc) {
      if (doc.type == type) {
        return doc.copyWith(
          status: DocumentStatus.completed,
          filePath:
              'uploaded/${type.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      return doc;
    }).toList();

    emit(state.copyWith(documents: completedDocs));
  }

  void completeBankDetails(BankDetails details) {
    final updatedDocs = state.documents.map((doc) {
      if (doc.type == DocumentType.bankDetails) {
        return doc.copyWith(
          status: DocumentStatus.completed,
          bankDetails: details,
        );
      }
      return doc;
    }).toList();
    emit(state.copyWith(documents: updatedDocs, clearError: true));
  }

  void removeDocument(DocumentType type) {
    final updatedDocs = state.documents.map((doc) {
      if (doc.type == type && doc.isCompleted) {
        return doc.copyWith(
          status: DocumentStatus.required,
          filePath: null,
          clearBankDetails: type == DocumentType.bankDetails,
        );
      }
      return doc;
    }).toList();
    emit(state.copyWith(documents: updatedDocs));
  }

  Future<void> submitForReview() async {
    final profileImageUploaded = DocumentProgressStore.isProfileImageUploaded();
    final syncedDocs = state.documents.map((doc) {
      final completed = DocumentProgressStore.isCompleted(doc.type);
      return doc.copyWith(
        status: completed ? DocumentStatus.completed : DocumentStatus.required,
      );
    }).toList();
    final docsComplete =
        profileImageUploaded && syncedDocs.every((doc) => doc.isCompleted);

    if (!docsComplete) {
      final String errorMessage = !profileImageUploaded
          ? 'Please upload your profile picture before proceeding.'
          : 'Please complete all required documents before submitting.';

      emit(
        state.copyWith(
          documents: syncedDocs,
          isProfileImageUploaded: profileImageUploaded,
          clearError: true,
        ),
      );
      emit(
        state.copyWith(
          documents: syncedDocs,
          isProfileImageUploaded: profileImageUploaded,
          errorMessage: errorMessage,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        documents: syncedDocs,
        isProfileImageUploaded: profileImageUploaded,
        isSubmitting: true,
        clearError: true,
      ),
    );

    try {
      final response = await _submitAllDataSource.submitAll(
        declarationAccepted: true,
      );

      final String submissionId = (response.submissionId ?? '').trim();
      if (submissionId.isNotEmpty) {
        await OnboardingSubmissionStore.save(
          submissionId: submissionId,
          status: response.status,
        );
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          isSubmitted: true,
          submissionId: submissionId.isNotEmpty ? submissionId : null,
          submissionStatus: response.status,
          submissionMessage: response.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString().replaceFirst('Exception: ', '').trim(),
        ),
      );
    }
  }

  void reset() {
    emit(VerificationState.initial());
  }

  void clearSubmitted() {
    emit(state.copyWith(isSubmitted: false));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
