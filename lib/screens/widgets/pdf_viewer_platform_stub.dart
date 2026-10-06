import 'package:flutter/material.dart';

Widget buildPlatformPdfViewer({
  required String url,
  required VoidCallback onLoaded,
  required ValueChanged<String> onFailed,
}) {
  return const Center(
    child: Text('Platform not supported'),
  );
}
