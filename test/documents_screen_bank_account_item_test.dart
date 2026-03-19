import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/features/document_verify/presentation/model/document_progress_store.dart';
import 'package:goapp/features/documents/data/datasources/documents_list_remote_data_source.dart';
import 'package:goapp/features/documents/data/models/documents_list_models.dart';
import 'package:goapp/features/documents/presentation/cubit/documents_cubit.dart';
import 'package:goapp/features/documents/presentation/pages/documents_screen.dart';

class _FakeDocumentsListRemoteDataSource
    implements DocumentsListRemoteDataSource {
  @override
  Future<DocumentsListResponseModel> fetchAll() async {
    return const DocumentsListResponseModel(success: true, documents: []);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DocumentProgressStore.reset();

    if (sl.isRegistered<DocumentsCubit>()) {
      sl.unregister<DocumentsCubit>();
    }
    sl.registerFactory<DocumentsCubit>(
      () => DocumentsCubit(
        remoteDataSource: _FakeDocumentsListRemoteDataSource(),
      ),
    );
  });

  tearDown(() {
    if (sl.isRegistered<DocumentsCubit>()) {
      sl.unregister<DocumentsCubit>();
    }
  });

  testWidgets('Documents screen shows bank account item', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DocumentsScreen()));

    // DocumentsCubit has an artificial 800ms delay.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    final linked = find.text('Linked Bank Account');
    final link = find.text('Link Bank Account');
    expect(linked.evaluate().length + link.evaluate().length, greaterThan(0));
  });
}
