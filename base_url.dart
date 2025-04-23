import 'dart:io' show Platform;  
import 'package:flutter/foundation.dart' show kIsWeb;

class UrlHelper {
  static String getBaseUrl() {
    String url;

    if (kIsWeb) {
      url = 'https://localhost:7091'; //for web
      //url = 'https://54.83.102.187:5001';
    } else if (Platform.isAndroid) {
      url = 'https://10.0.2.2:7091'; //for android
      //url = 'https://54.83.102.187:5001';
    } else {
      url = 'https://localhost:7091'; //default case (iOS or others)
      //url = 'https://54.83.102.187:5001';
    }

    return url;
  }
}