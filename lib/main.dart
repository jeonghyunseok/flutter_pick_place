import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() => runApp(
      const PickApp(),
    );

class PickApp extends StatefulWidget {
  const PickApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PickAppState createState() => _PickAppState();
}

class _PickAppState extends State<PickApp> {
  late StreamSubscription _intentDataStreamSubscription;
  String? _sharedText;
  String? _sharedUrl;
  String? _parsedData;

  @override
  void initState() {
    super.initState();

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    initSharedText();

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      setState(() {
        _sharedText = value;
        debugPrint("Shared: $_sharedText");
      });
    });
  }

  void initSharedText() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        _sharedText = value;
        debugPrint("Shared: $_sharedText");
        // Check if the shared text contains "https://"
        if (_sharedText != null) {
          // Regular expression for URLs
          RegExp regex = RegExp(r"(https?://[^\s]+)");
          Iterable<Match> matches = regex.allMatches(_sharedText!);
          if (matches.isNotEmpty) {
            _sharedUrl = matches.first.group(0);
            fetchAndParse(_sharedUrl!);
          }
        }
      });
    }, onError: (err) {
      debugPrint("getLinkStream error: $err");
    });
  }

  Future<void> fetchAndParse(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = parse(response.body);
      var metaTags = document.getElementsByTagName("meta");

      String metaData = "";
      String mapType = '';
      for (var metaTag in metaTags) {
        if (metaTag.attributes["property"] == 'og:title') {
          metaData += "${metaTag.attributes["content"]}\n";
          mapType = metaTag.attributes["content"] ?? '';
        }
        if (metaTag.attributes["property"] == 'og:image') {
          if (mapType == 'Google Maps') {
            RegExp centerPattern = RegExp(r'center=([-\d.]+)%2C([-\d.]+)');
            Match? centerMatch =
                centerPattern.firstMatch(metaTag.attributes["content"] ?? "");
            if (centerMatch != null) {
              String latitude = centerMatch.group(1) ?? '';
              String longitude = centerMatch.group(2) ?? '';
              metaData += "latitude: $latitude\n";
              metaData += "longitude: $longitude\n";
            }
          } else {
            metaData += "image:${metaTag.attributes["content"]}\n";
          }
        }
      }
      setState(() {
        _parsedData = metaData;
      });
    } else {
      throw Exception('Failed to load HTML');
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: InAppWebView(
          initialUrlRequest:
              URLRequest(url: Uri.parse("http://localhost:3000/")),
        ),
      ),
    );
  }
}
