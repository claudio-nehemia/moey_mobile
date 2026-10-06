import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

Widget buildPlatformPdfViewer({
  required String url,
  required VoidCallback onLoaded,
  required ValueChanged<String> onFailed,
}) {
  return SfPdfViewer.network(
    url,
    onDocumentLoaded: (PdfDocumentLoadedDetails details) => onLoaded(),
    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) => onFailed(details.description),
  );
}
