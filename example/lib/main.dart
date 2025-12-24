import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf_merger_flutter/my_pdf_merger.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'PDF Merger', home: PDFMergeScreen());
  }
}

class PDFMergeScreen extends StatefulWidget {
  const PDFMergeScreen({super.key});

  @override
  PDFMergeScreenState createState() => PDFMergeScreenState();
}

class PDFMergeScreenState extends State<PDFMergeScreen> {
  final TextEditingController _fileNameController = TextEditingController();
  final List<String> _pdfUrls = [];
  final List<Uint8List> _pdfBytesList = [];
  bool _isLoading = false;

  Future<void> _combinePDFs() async {
    if (_fileNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a file name')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Uint8List mergedBytes = await MyPdfService.combinePDFs(localBytes: _pdfBytesList);
      await MyPdfService.openMerged(mergedBytes, "${_fileNameController.text}.pdf");
    } catch (e) {
      if (context.mounted) {}
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _pickFilesToAdd() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        // if (kIsWeb) {
          _pdfBytesList.add(result.files.first.bytes!);
        // }
        _pdfUrls.addAll(result.files.map((file) => file.path!));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Merger')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_pdfUrls.isNotEmpty)
              TextField(
                controller: _fileNameController,
                decoration: InputDecoration(labelText: 'Enter file name'),
              ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _pickFilesToAdd, child: Text('Pick PDFs')),
            Expanded(
              child: ListView.builder(
                itemCount: _pdfUrls.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text('PDF ${index + 1}'), subtitle: Text(_pdfUrls[index]));
                },
              ),
            ),
            if (_pdfUrls.length > 1)
              ElevatedButton(
                onPressed: _combinePDFs,
                child: _isLoading ? CircularProgressIndicator() : Text('Merge PDFs'),
              ),
          ],
        ),
      ),
    );
  }
}
