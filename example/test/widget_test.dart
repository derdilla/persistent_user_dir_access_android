import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_user_dir_access_android/persistent_user_dir_access_android.dart';

import 'package:persistent_user_dir_access_android_example/main.dart';

void main() {
  testWidgets('Builds sample controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: App()));
    expect(find.text('User dir sample app'), findsOneWidget);
    expect(find.text('requestDirectoryUri()'), findsOneWidget);
    expect(find.text('Selected directory: null'), findsOneWidget);
    expect(
        find.text(
            "writeFile(uri, 'test.txt', 'text/plain', utf8.encode('Test text'))"),
        findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('Calls requestDirectoryUri', (WidgetTester tester) async {
    final plugin = MockPersistentUserDirAccessAndroid();
    await tester.pumpWidget(MaterialApp(home: App(userDirs: plugin)));

    expect(plugin.methodInvokeHistory, isEmpty);
    await tester.tap(find.text('requestDirectoryUri()'));
    await tester.pump();
    expect(plugin.methodInvokeHistory, hasLength(1));
    expect(plugin.methodInvokeHistory[0], 'requestDirectoryUri');

    plugin.sampleUri = 'Some sample uri for testing ;)';
    expect(find.textContaining(plugin.sampleUri!), findsNothing);
    await tester.tap(find.text('requestDirectoryUri()'));
    await tester.pump();
    expect(plugin.methodInvokeHistory, hasLength(2));
    expect(plugin.methodInvokeHistory[1], 'requestDirectoryUri');
    expect(find.textContaining(plugin.sampleUri!), findsOneWidget);
  });

  testWidgets('Passes arguments to writeFile', (WidgetTester tester) async {
    final plugin = MockPersistentUserDirAccessAndroid();
    plugin.sampleUri = 'test://uri';
    await tester.pumpWidget(MaterialApp(home: App(userDirs: plugin)));

    expect(plugin.methodInvokeHistory, isEmpty);
    await tester.tap(find.text('requestDirectoryUri()'));
    await tester.pump();
    expect(plugin.methodInvokeHistory, hasLength(1));
    expect(plugin.methodInvokeHistory[0], 'requestDirectoryUri');

    await tester.tap(find.text(
        "writeFile(uri, 'test.txt', 'text/plain', utf8.encode('Test text'))"));
    await tester.pump();
    expect(plugin.methodInvokeHistory, hasLength(2));
    expect(plugin.methodInvokeHistory[1],
        'writeFile(test://uri,test.txt,text/plain, [84, 101, 115, 116, 32, 116, 101, 120, 116])');
  });
}

class MockPersistentUserDirAccessAndroid
    implements PersistentUserDirAccessAndroid {
  final List<String> methodInvokeHistory = [];
  String? sampleUri;
  bool writeFileResult = true;

  @override
  Future<String?> requestDirectoryUri() async {
    methodInvokeHistory.add('requestDirectoryUri');
    return sampleUri;
  }

  @override
  Future<bool> writeFile(
      String dirUri, String fileName, String mimeType, Uint8List data) async {
    methodInvokeHistory.add('writeFile($dirUri,$fileName,$mimeType, $data)');
    return writeFileResult;
  }
}
