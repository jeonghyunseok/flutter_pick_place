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
      String mapType ='';
      for (var metaTag in metaTags) {
        if (metaTag.attributes["property"] == 'og:title') {
          metaData += "${metaTag.attributes["content"]}\n";
          mapType = metaTag.attributes["content"] ?? '';
        }        
        if (metaTag.attributes["property"] == 'og:image') {
           if (mapType == 'Google Maps') {
              RegExp centerPattern = RegExp(r'center=([-\d.]+)%2C([-\d.]+)');
              Match? centerMatch = centerPattern.firstMatch(metaTag.attributes["content"] ?? "");
              if (centerMatch != null) {
                String latitude = centerMatch.group(1) ?? '';
                String longitude = centerMatch.group(2) ?? '';
                metaData += "latitude: $latitude\n";
                metaData += "longitude: $longitude\n";
              }
            }else{
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

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_parsedData ?? ''),
        ),
        body: const Center(
          child: Column(
            children: <Widget>[
              Text('지도1')
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: '팔로우',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections),
              label: '컬렉션',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '내정보',
            ),
          ],
          currentIndex: _currentIndex,
          selectedItemColor: Colors.purple, 
          unselectedItemColor: Colors.purple.withOpacity(0.3), 
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

}