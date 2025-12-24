# pdf_merger_flutter

A new Flutter project.

## Getting Started

This package is developed for merging multiple files with each other, you can pass url and bytes.
urls have priority to bytes so if you upload url, the first files are the uploaded urls.

To use this package call [combinePDFs]: 

```dart
Future<Uint8List> combinePDFs({List<String>? urls, List<Uint8List>? localBytes}) {}
```

This Returns a Uint8List that is a merged pdf file of yours containing each pdf that you have passed to this method.

if you have question please contact me or fork the repo.
