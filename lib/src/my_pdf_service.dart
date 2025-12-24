/// A library for merging and opening PDF files within a Flutter application.
library pdf_merger_flutter;

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// A service class providing utility methods for PDF manipulation.
///
/// This class handles merging multiple PDF byte streams and opening
/// PDF files using the device's default application.
class MyPdfService {
  /// Private constructor to prevent instantiation of this utility class.
  MyPdfService._();

  /// Combines multiple PDF documents into a single PDF document.
  ///
  /// Takes a list of [localBytes], where each [Uint8List] represents a PDF file.
  /// Returns a [Future] that completes with the [Uint8List] of the merged PDF.
  static Future<Uint8List> combinePDFs({List<Uint8List>? localBytes}) async {
    List<Uint8List> allPdfBytes = [];

    if (localBytes != null) {
      allPdfBytes.addAll(localBytes);
    }

    return await _mergePdfs(allPdfBytes);
  }

  /// Internal helper to merge PDF bytes using the Syncfusion PDF engine.
  static Future<Uint8List> _mergePdfs(List<Uint8List> pdfBytesList) async {
    PdfDocument newDocument = PdfDocument();
    PdfSection? section;
    for (Uint8List byte in pdfBytesList) {
      PdfDocument loadedDocument = PdfDocument(inputBytes: byte);
      for (int index = 0; index < loadedDocument.pages.count; index++) {
        PdfTemplate template = loadedDocument.pages[index].createTemplate();
        if (section == null || section.pageSettings.size != template.size) {
          section = newDocument.sections!.add();
          section.pageSettings.size = template.size;
          section.pageSettings.margins.all = 0;
        }

        section.pages.add().graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
        );
      }

      loadedDocument.dispose();
    }
    List<int> bytes = await newDocument.save();
    newDocument.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Saves the provided [bytes] as a temporary file and opens it.
  ///
  /// The [fileName] should include the `.pdf` extension. The file is saved
  /// in the application's temporary directory and opened using [OpenAppFile].
  static Future<void> openMerged(Uint8List bytes, String fileName) async {
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await OpenAppFile.open(file.path);
  }
}
