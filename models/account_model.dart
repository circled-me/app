import 'dart:convert';
import 'dart:io' show Platform;
import 'package:app/main.dart';
import 'package:app/services/websocket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:push/push.dart';

import 'package:app/models/user_model.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';

class AccountModel {
  static const isDebugMode = kDebugMode || String.fromEnvironment("DEBUG") == "1";
  static const _pushServer = "https://push.circled.me";
  final String server, name, token;
  final int userID; // Remote user id
  final bool autoBackup;
  final List<int> permissions;
  int bucketUsage;
  int bucketQuota;
  String pushToken;
  ApiClient? _apiClient;
  bool? _canUpload;
  bool? _canCreateGroups;
  bool? _hasBackup;
  bool? _isAdmin;
  AccountModel({required this.server, required this.name, required this.token, required this.userID,
      required this.permissions, this.autoBackup = false, this.bucketUsage=-1, this.bucketQuota=-1, this.pushToken=""});

  bool canUploadToServer() {
    _canUpload ??= permissions.contains(UserModel.permissionPhotoUpload);
    return _canUpload!;
  }

  bool canCreateGroups() {
    _canCreateGroups ??= (permissions.contains(UserModel.permissionCanCreateGroups) || isAdmin());
    return _canCreateGroups!;
  }

  bool hasBackup() {
    _hasBackup ??= permissions.contains(UserModel.permissionPhotoBackup);
    return _hasBackup!;
  }

  bool isAdmin() {
    _isAdmin ??= permissions.contains(UserModel.permissionAdmin); // List is not long so this is ok
    return _isAdmin!;
  }

  String get serverName => server.replaceFirst("https://", "").replaceFirst("http://", "");

  ApiClient get apiClient {
    _apiClient ??= ApiClient(server, token: token);
    return _apiClient!;
  }

  get hasUsageInfo => bucketUsage > -1;
  get hasQuotaInfo => bucketQuota > 0;

  String _readableSize(int size) {
    return size < 1024 ? size.toString()+"MB" : (size/1024).toStringAsFixed(1)+"GB";
  }
  get getUsageAsString => _readableSize(bucketUsage);
  get getQuotaAsString => _readableSize(bucketQuota);

  static AccountModel fromJson(JSONObject json) {
    return AccountModel(
      server: json["server"],
      name: json["name"],
      token: json["token"],
      userID: json["user_id"],
      autoBackup: json["autoBackup"],
      bucketUsage: json["bucket_usage"]!=null ? json["bucket_usage"].toInt() : -1,
      bucketQuota: json["bucket_quota"]!=null ? json["bucket_quota"].toInt() : -1,
      permissions: json["permissions"].cast<int>(),
    );
  }

  JSONObject toJson() {
    return {
      "server": server,
      "token" : token,
      "name"  : name,
      "user_id": userID,
      "permissions": permissions,
      "autoBackup": autoBackup,
    };
  }

  Map<String, String> get requestHeaders => {"Cookie": "token="+token};

  String get getDisplayName => _removeEmailDomain(name)+"@"+_removeProtocol(serverName);
  String get identifier => userID.toString()+"#"+serverName;

  Future<ApiResponse> logout() async {
    await apiClient.emptyCache();
    await Push.instance.token.then((token) {
      http.post(Uri.parse("$_pushServer/deregister"), body: jsonEncode({
        "type": Platform.isIOS ? 0 : 1, // only iOS and Android supported
        "user_token": pushToken,
        "service_token": token!
      }));
    });
    return apiClient.post("/user/logout");
  }

  String _removeEmailDomain(String s) {
    final index = s.indexOf("@");
    if (index == -1) {
      return s;
    }
    return s.substring(0, index);
  }
  String _removeProtocol(String url) {
    if (url.toLowerCase().startsWith("https://")) {
      return url.substring(8);
    }
    if (url.toLowerCase().startsWith("http://")) {
      return url.substring(7);
    }
    return url;
  }

  void updatePushServer() async {
    print("called updatePushServer");
    String voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    Push.instance.token.then((token) {
      final payload = jsonEncode({
        "type": Platform.isIOS ? 0 : 1, // only iOS and Android supported
        "user_token": pushToken,
        "voip_token": voipToken,
        "service_token": token!,
        "debug_mode": isDebugMode ? 1 : 0,
        "app_version": MyApp.version,
        "badge_count": MyApp.numUnread,
      });
      print("PUSH PAYLOAD: $payload");
      http.post(Uri.parse(_pushServer+"/register"), body: payload).then((response) {
        if (response.statusCode != 200) {
          print(response.request!.url.toString()+" was not successful");
          print(response.body);
        }
      });
    });
  }

  Future<bool> updateStatus() async {
    final response = await apiClient.get("/user/status");
    if (response.status != 200) {
      return false;
    }
    final json = jsonDecode(response.body);
    permissions.clear();
    permissions.addAll(json["permissions"].cast<int>());

    bucketUsage = json["bucket_usage"]!=null ? json["bucket_usage"].toInt() : -1;
    bucketQuota = json["bucket_quota"]!=null ? json["bucket_quota"].toInt() : -1;
    pushToken = json["push_token"];

    updatePushServer();
    return true;
  }

  Future<ApiResponse> getCallPath(bool reset) async {
    return apiClient.get("/user/video-link?reset=${reset ? "1" : "0"}");
  }
}
