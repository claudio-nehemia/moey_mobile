// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformPdfViewer({
  required String url,
  required VoidCallback onLoaded,
  required ValueChanged<String> onFailed,
}) {
  final String viewType = 'pdf-iframe-${url.hashCode}';

  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..onLoad.listen((_) => onLoaded())
        ..onError.listen((_) => onFailed('Gagal memuat dokumen di frame web.'));
      return iframe;
    },
  );

  return HtmlElementView(viewType: viewType);
}
