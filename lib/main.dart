import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;
  String? _sharedText;
  String? _sharedUrl;
  String? _parsedData;

  @override
  void initState() {
    super.initState();

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
          setState(() {
            _sharedText = value;
            print("Shared: $_sharedText");
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
          print("getLinkStream error: $err");
        });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      setState(() {
        _sharedText = value;
        print("Shared: $_sharedText");
      });
    });
  }

Future<void> fetchAndParse(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = parse(response.body);
      var metaTags = document.getElementsByTagName("meta");

      String metaData = "";
      for (var metaTag in metaTags) {
        if (metaTag.attributes["property"] != null &&
            metaTag.attributes["content"] != null) {
          metaData += "${metaTag.attributes["property"]}: ${metaTag.attributes["content"]}\n";
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
    const textStyleBold = const TextStyle(fontWeight: FontWeight.bold);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              const Text("Shared text:", style: textStyleBold),
              Text(_sharedText != null ? Uri.decodeFull(_sharedText!) : ""),
              const Text("Shared URL:", style: textStyleBold),
              Text(_sharedUrl != null ? Uri.decodeFull(_sharedUrl!) : ""),
              const Text("Parsed Meta Data:", style: textStyleBold),
              Text(_parsedData != null ? _parsedData! : "")
            ],
          ),
        ),
      ),
    );
  }
}