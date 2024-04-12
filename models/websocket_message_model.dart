
import 'dart:convert';

import 'package:app/services/api_client.dart';

class WebSocketMessage {
  final String type;
  final int stamp;
  final dynamic data;
  WebSocketMessage(this.type, this.stamp, this.data);

  static WebSocketMessage fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(json["type"] as String, json["stamp"] as int, json["data"]);
  }

  JSONObject toJson() {
    return {
      "type": type,
      "stamp": stamp,
      "data": data,
    };
  }
}
