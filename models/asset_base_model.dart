import 'dart:convert';
import 'dart:io';

import 'package:app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widget/cached_thumb_widget.dart';
import 'account_model.dart';


class MultiResultResponse {
  final int status;
  final String error;
  final Set<int> failedIds;
  MultiResultResponse(this.status, this.error, this.failedIds);

  static MultiResultResponse from(ApiResponse response) {
    final json = jsonDecode(response.body);
    return MultiResultResponse(response.status, json["error"] as String? ??"", json["failed"]!=null?Set<int>.from(List<int>.from(json["failed"])):{});
  }
}

abstract class AssetBaseModel {
  static const typeOther = 0;
  static const typeImage = 1;
  static const typeVideo = 2;
  static const heroBaseThumb = "base";

  int id = 0;
  int type = 0;
  int createdAt = 0; // time is adjusted so it can be rendered as UTC
  int size = 0;
  int owner = 0;
  String deviceId = "";
  String name = "";
  double? gpsLat, gpsLong;
  String? location;

  bool get isOwn => false;

  AssetBaseModel(this.id, this.name, this.owner, this.createdAt, this.type, this.deviceId, this.gpsLat, this.gpsLong, this.location, this.size);

  get createdDate {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt*1000, isUtc: true);
    final df = DateFormat("EEEE・d MMMM yyyy・HH:mm");
    return df.format(dt);
  }

  bool get isImage => type == typeImage;
  bool get isVideo => type == typeVideo;

  get isFavourite => false;
  String readableSize() {
    if (size < 1024*1024) {
      return (size/1024).toStringAsFixed(1)+"KB";
    }
    if (size < 10*1024*1024) {
      return (size / 1024 / 1024).toStringAsFixed(1) + "MB";
    }
    return (size/1024/1024).toStringAsFixed(0)+"MB";
  }

  String getHeroTag(String variation);

  String get uri;
  String get bigThumbUrl => uri+"&thumb=1";
  String get thumbUrl => uri+"&thumb=1&size=250";
  String get albumThumbUrl => uri+"&thumb=1&size=500";
  Map<String, String> get requestHeaders => {};
  static Future<MultiResultResponse?> deleteAtRemote(AccountModel account, List<int> ids) async {
    return null;
  }
  Future<bool> doFavourite(int albumId) async {
    return false;
  }
  Future<bool> doUnfavourite(int albumId) async {
    return false;
  }
  Future<File?> download();

  Widget getThumb(bool selected) {
    Widget thumb = CachedThumb(asset: this, fit: true, selected: selected);
    if (!isVideo) {
      return thumb;
    }
    // Video
    return Stack(
      fit: StackFit.expand,
      children: [
        thumb,
        Positioned(right: 3, bottom: 4, child: Icon(Icons.play_circle_outline, color: Colors.black.withOpacity(0.4))),
        const Positioned(right: 5, bottom: 5, child: Icon(Icons.play_circle_outline, color: Colors.white)),
      ],
    );
  }
}
