import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:persistent_user_dir_access_android/persistent_user_dir_access_android.dart';

void main() => runApp(const MaterialApp(home: App()));

/// Sample app showcasing persistent_user_dir_access_android plugin.
class App extends StatefulWidget {
  /// Create sample app showcasing persistent_user_dir_access_android plugin.
  ///
  /// Requires [MaterialApp] ancestor.
  const App({
    super.key,
    this.userDirs = const PersistentUserDirAccessAndroid(),
  });

  /// User dirs implementation.
  final PersistentUserDirAccessAndroid userDirs;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String? _uri;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('User dir sample app')),
    body: ListView(
      children: [
        Card(child: Text('Selected directory: $_uri')),
        ListTile(
          title: const Text('requestDirectoryUri()'),
          onTap: () async {
            final dirUri = await widget.userDirs.requestDirectoryUri();
            setState(() {
              _uri = dirUri;
            });
          },
        ),
        ListTile(
          title: const Text(
            "writeFile(uri, 'test.txt', 'text/plain', utf8.encode('Test text'))",
          ),
          onTap: _uri == null
              ? null
              : () async {
                  await widget.userDirs.writeFile(
                    _uri!,
                    'test.txt',
                    'text/plain',
                    utf8.encode('Test text'),
                  );
                },
        ),
      ],
    ),
  );
}
