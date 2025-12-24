import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class MyPdfService {
  static final Dio _dio = Dio();

  static Future<Uint8List> combinePDFs({List<String>? urls, List<Uint8List>? localBytes}) async {
    List<Uint8List> allPdfBytes = [];

    if (urls != null) {
      for (var url in urls) {
        allPdfBytes.add(await _fetchUrlBytes(url));
      }
    }

    if (localBytes != null) {
      allPdfBytes.addAll(localBytes);
    }

    return await _mergePdfs(allPdfBytes);
  }

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

        section.pages.add().graphics.drawPdfTemplate(template, const Offset(0, 0));
      }

      loadedDocument.dispose();
    }
    List<int> bytes = await newDocument.save();
    newDocument.dispose();
    return Uint8List.fromList(bytes);
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
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await OpenAppFile.open(file.path);
  }
}
