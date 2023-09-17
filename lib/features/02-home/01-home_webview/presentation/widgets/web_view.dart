import 'dart:io';

import 'package:dio/dio.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phonoi_app/core/utils/widgets/snackbars_widgets.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage({required this.url});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController _webController;
  double _progress = 0;
  TextEditingController _urlController = TextEditingController();
  String? _currentUrl;

  Future<WebResourceResponse?> _shouldInterceptRequest(InAppWebViewController controller, String url) async {
    // Check if the resource being loaded is a Reels video
    if (url.contains('/reel/') && url.endsWith('.mp4')) {
      // Update the current URL to the new video URL
      setState(() {
        _currentUrl = url;
      });
      // Load the new video URL in the WebView
      controller.loadUrl(urlRequest: URLRequest(url: Uri.parse(_currentUrl!)));
    }
    return null;
  }

  String urlNew = "";
  @override
  void initState() {
    super.initState();
    _urlController.text = widget.url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _urlController,
                onTap: () => {},
                onSubmitted: (value) {
                  _loadUrl();
                },
                style: TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  constraints: BoxConstraints(
                    maxHeight: 57.h,
                    maxWidth: 360.w,
                  ),
                  fillColor: const Color(0xffEBEBEB),
                  filled: true,
                  hintText: "البحث أو كتابة عنوان الويب",
                  hintStyle: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  prefixIcon: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Center(
                        child: Icon(Icons.search, color: Colors.white, size: 24),
                      )),
                  suffixIcon: SizedBox(
                    width: 10.5.w,
                    height: 10.5.h,
                    child: GestureDetector(
                        onTap: (){
                          if(urlNew != null)
                          downloadVideo( );
                        },
                        child: isLoading == false ?

                        urlNew != null && urlNew.isNotEmpty ?Icon(Icons.download_for_offline_rounded,
                        color: Colors.deepPurple,) : Image.asset("assets/icons/google.png") :
                        Center(
                          child: Container(
                              padding: EdgeInsets.all(2),
                              height: 18,width: 18,
                              child: Center(child: CircularProgressIndicator(color: Colors.black))),
                        )),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            _progress < 1.0
                ? LinearProgressIndicator(
                    value: _progress,
                    color: Colors.blue,
                  )
                : Container(),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
                onWebViewCreated: (InAppWebViewController controller) {
                  _webController = controller;
                },
                onUpdateVisitedHistory: (   controller, Uri? url,   androidIsReload) {


                  if(url.toString() != "https://m.youtube.com/" && url.toString().contains("youtube")) {
                    urlNew = url.toString();
                    setState(() {

                    });
                  }
                },
                onLoadStart: (InAppWebViewController controller, Uri? url) {
                  setState(() {
                    _urlController.text = url?.toString() ?? '';


                  });
                },
                onLoadStop: (InAppWebViewController controller, Uri? url) async {
                  setState(
                    () {
                      _urlController.text = url?.toString() ?? '';
                      _progress = 1.0;

                    },
                  );
                },
                onProgressChanged: (InAppWebViewController controller, int progress) {
                  setState(
                    () {
                      _progress = progress / 100;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            label: 'Back',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_forward_ios, color: Colors.black),
            label: 'Forward',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh, color: Colors.black),
            label: 'Reload',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              color: Colors.black,
            ),
            label: 'Reload',
          ),
        ],
        onTap: (int index) {
          if (index == 0) {
            _webController.goBack();
          } else if (index == 1) {
            _webController.goForward();
          } else if (index == 2) {
            _webController.reload();
          } else if (index == 3) {
            _webController.webStorage;
          }
        },
      ),
    );
  }

  void _loadUrl() {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }
    setState(() {
      _progress = 0; // إعادة تعيين قيمة الاكتمال إلى الصفر عند بدء التحميل الجديد
    });
    _webController.loadUrl(urlRequest: URLRequest(url: Uri.parse(url)));
  }



  String progress = "";
  bool isLoading = false;

  Future<void> downloadVideo() async {
    isLoading = true ;
    setState(() {

    });

    print(urlNew);
    final yt = YoutubeExplode();
    final manifest = await yt.videos.streamsClient.getManifest(urlNew.split("=").last.split("&").first);

    print(manifest);

    // Get highest quality muxed stream
    var streamInfo = manifest.muxed.withHighestBitrate();

    if (streamInfo != null) {
      // Get the actual stream

      var stream = yt.videos.streamsClient.get(streamInfo);

      // Open a file for writing.

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      var directory = await DownloadsPathProvider.downloadsDirectory;
     String path = "${directory!.path}/" +
    "tube"+urlNew.split("=").last.split("&").first
        .replaceAll(new RegExp(r'[^\w\s]+'), '')
        .split(" ")
        .join("") +
    ".mp4";


      var file = File(path);
      var fileStream = file.openWrite();


      // Pipe all the content of the stream into the file.
      await stream.pipe(fileStream);


      // Close the file.
      await fileStream.flush();
      await fileStream.close();

    }
    isLoading = false ;

    setState(() async {
      await showSnackBar("تم تنزيل الملف بنجاح", 3, context);
    });
    yt.close();

  }
}
