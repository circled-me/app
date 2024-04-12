
import 'dart:io';

import 'package:app/models/asset_base_model.dart';
import 'package:app/services/api_client.dart';

class ExternalAssetModel extends AssetBaseModel {
  final String baseUrl;

  ExternalAssetModel(this.baseUrl, int id, String name, int owner, int createdAt, int type, String deviceId, double? gpsLat, double? gpsLong, String? location, int size)
    : super(id, name, owner, createdAt, type, deviceId, gpsLat, gpsLong, location, size);

  static ExternalAssetModel from(String url, Map<String, dynamic> json) {
    return ExternalAssetModel(url, json["id"], json["name"], json["owner"], json["created"], json["type"], json["did"],
      json["gps_lat"]!=null?json["gps_lat"].toDouble():null,
      json["gps_long"]!=null?json["gps_long"].toDouble():null,
      json["location"]!=null?json["location"].toString():null,
      json["size"]!=null?json["size"].toInt():0,
    );
  }

  @override
  Future<File?> download() async {
    final response = await ApiClient.generic.get(downloadUri, asFile: true);
    return response.file;
  }

  @override
  String getHeroTag(String variation) {
    return "ExternalAssetTag-"+variation+"-"+ baseUrl + id.toString();
  }

  @override
  String get uri => baseUrl + "asset?id=" + id.toString();
  String get downloadUri => uri + "&download=1";
}
