import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;

class MyPdfService {
  static final Dio _dio = Dio();

  static Future<Uint8List> combinePDFs({List<String>? urls, List<String>? localPaths}) async {
    List<Uint8List> allPdfBytes = [];

    if (urls != null) {
      for (var url in urls) {
        allPdfBytes.add(await _fetchUrlBytes(url));
      }
    }

    if (!kIsWeb && localPaths != null) {
      for (var path in localPaths) {
        final File file = File(path);
        if (await file.exists()) {
          allPdfBytes.add(await file.readAsBytes());
        }
      }
    }

    return await _mergePdfs(allPdfBytes);
  }

  static Future<Uint8List> _mergePdfs(List<Uint8List> pdfBytesList) async {
    PdfDocument newDocument = PdfDocument();

    for (Uint8List bytes in pdfBytesList) {
      PdfDocument loadedDocument = PdfDocument(inputBytes: bytes);
      for (int i = 0; i < loadedDocument.pages.count; i++) {
        PdfTemplate template = loadedDocument.pages[i].createTemplate();
        newDocument.pages.add().graphics.drawPdfTemplate(template, Offset.zero);
      }
      loadedDocument.dispose();
    }

    List<int> mergedBytes = await newDocument.save();
    newDocument.dispose();
    return Uint8List.fromList(mergedBytes);
  }

  static Future<Uint8List> _fetchUrlBytes(String url) async {
    final response = await _dio.get(url, options: Options(responseType: ResponseType.bytes));
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception("Failed to download PDF from $url");
    }
  }

  static Future<void> openMerged(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      final html.Blob blob = html.Blob([bytes], 'application/pdf');
      final String url = html.Url.createObjectUrlFromBlob(blob);

      html.window.open(url, "_blank");

      Future.delayed(const Duration(minutes: 1), () => html.Url.revokeObjectUrl(url));
    } else {
      final Directory directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await OpenAppFile.open(file.path);
    }
  }
}
