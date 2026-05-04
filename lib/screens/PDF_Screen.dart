import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

// import 'package:pdfx/pdfx.dart' as pdf;
// import 'package:pdfx/pdfx.dart';

import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class PDFViewer extends StatefulWidget {
  final String invoice;
  final String? filename;

  PDFViewer({required this.invoice, this.filename = ""});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  // PdfController? pdfController;

  @override
  void initState() {
    super.initState();
    // viewPDF();
  }

  /*
  Future<void> viewPDF() async {
    try {
      pdfController = PdfController(
        document: pdf.PdfDocument.openData(InternetFile.get(
          "${widget.invoice}",
        )),
        initialPage: 0,
      );
    } catch (e) {}
  }
  */

  Future<void> downloadPDF() async {
    appStore.setLoading(true);
    final response = await http.get(Uri.parse(widget.invoice));
    if (response.statusCode == 200) {
      try {
        final bytes = response.bodyBytes;
        String path = "~";
        if (Platform.isIOS) {
          var directory = await getApplicationDocumentsDirectory();
          path = directory.path;
        } else {
          path = "/storage/emulated/0/Download";
        }
        String fileName = widget.filename.validate().isEmpty ? "invoice" : widget.filename.validate();
        File file = File('${path}/${fileName}.pdf');
        await file.writeAsBytes(bytes, flush: true);
        appStore.setLoading(false);
        toast("invoice downloaded at ${file.path}");
        // final url = 'content://${file.path}';
        final filef = File(file.path);
        if (await filef.exists()) {
          OpenFile.open(file.path);
        } else {
          throw 'لا يوجد ملف';
        }
      } catch (e) {
        throw Exception('فشل تحميل الفاتورة');
      }
    } else {
      appStore.setLoading(false);
      toast("فشل تحميل الفاتورة");
      throw Exception('فشل تحميل الفاتورة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                image: DecorationImage(
                  image: AssetImage(IMAGE_BACKGROUND),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            automaticallyImplyLeading: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text("الفاتورة", style: boldTextStyle(color: Colors.white)),
            actions: [
              IconButton(
                onPressed: () {
                  downloadPDF();
                },
                icon: Icon(Icons.download, color: Colors.white),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // PdfView(controller: pdfController!),
            // PdfPageNumber(
            //   controller: pdfController!,
            //   builder: (_, loadingState, page, pagesCount) {
            //     if (page == 0) return loaderWidget();
            //     return SizedBox();
            //   },
            // ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("لا يوجد عرض PDF متاح حالياً.", style: boldTextStyle(size: 18)),
                  SizedBox(height: 8),
                  Text("يرجى استخدام زر التحميل لعرض الفاتورة.", style: primaryTextStyle()),
                ],
              ),
            ),
            Observer(
                builder: (context) =>
                    Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
          ],
        ));
  }
}
