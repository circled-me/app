import 'dart:convert';
import 'dart:io';

import 'package:app/models/asset_base_model.dart';
import 'package:app/models/face_model.dart';
import 'account_model.dart';

class AssetModel extends AssetBaseModel {

  final AccountModel account;
  bool favourite;
  List<FaceModel> faces = [];
  bool _facesLoaded = false;

  @override
  bool get isOwn => account.userID == owner;

  AssetModel(this.account, int id, String name, int owner, int createdAt, int type, String deviceId, double? gpsLat, double? gpsLong, String? location, int size, {this.favourite=false})
    : super(id, name, owner, createdAt, type, deviceId, gpsLat, gpsLong, location, size);

  AssetModel.hero(this.account, int id, {int owner=0, int type=AssetBaseModel.typeImage, String name="", int createdAt=0, String deviceId="", int size=0, this.favourite=false})
    : super(id, name, owner, createdAt, type, deviceId, null, null, null, size);

  static AssetModel fromAccountJson(AccountModel account, Map<String, dynamic> json) {
    return AssetModel(account, json["id"], json["name"], json["owner"], json["created"], json["type"], json["did"],
                      json["gps_lat"]!=null?json["gps_lat"].toDouble():null,
                      json["gps_long"]!=null?json["gps_long"].toDouble():null,
                      json["location"]!=null?json["location"].toString():null,
                      json["size"]!=null?json["size"].toInt():0,
                      favourite: json["favourite"]??false,
    );
  }
  @override
  get isFavourite => favourite;

  // Example: AssetTag-AlbumTag-5
  @override
  String getHeroTag(String variation) {
    return "AssetTag-"+variation+"-"+id.toString();
  }

  @override
  String get uri => account.server+"/asset/fetch?id="+id.toString();
  @override
  Map<String, String> get requestHeaders => {"Cookie": "token="+account.token};

  static Future<MultiResultResponse> deleteAtRemote(AccountModel account, List<int> ids) async {
    var result = await account.apiClient.post("/asset/delete", body: jsonEncode({
      "ids": ids
    }));
    return MultiResultResponse.from(result);
  }

  static Future<MultiResultResponse> addToAlbum(AccountModel account, int albumId, List<int> ids) async {
    var result = await account.apiClient.post("/album/add", body: jsonEncode({
      "asset_ids": ids,
      "album_id": albumId,
    }));
    return MultiResultResponse.from(result);
  }

  static Future<MultiResultResponse> removeFromAlbum(AccountModel account, int albumId, List<int> ids) async {
    var result = await account.apiClient.post("/album/remove", body: jsonEncode({
      "asset_ids": ids,
      "album_id": albumId,
    }));
    return MultiResultResponse.from(result);
  }

  @override
  bool canFavourite() {
    return true;
  }
  Future<bool> doFavourite(int albumId) async {
    var result = await account.apiClient.post("/asset/favourite", body: jsonEncode({
      "id": id,
      "album_asset_id": albumId,
    }));
    if (result.status == 200) {
      favourite = true;
      return true;
    }
    return false;
  }

  Future<bool> doUnfavourite(int albumId) async {
    var result = await account.apiClient.post("/asset/unfavourite", body: jsonEncode({
      "id": id,
      "album_asset_id": albumId,
    }));
    if (result.status == 200) {
      favourite = false;
      return true;
    }
    return false;
  }

  Future<File?> download() async {
    final result = await account.apiClient.get("/asset/fetch?id="+id.toString(), asFile: true);
    return result.file;
  }

  Future<void> _loadFaces() async {
    final result = await account.apiClient.get("/faces/for-asset?asset_id="+id.toString());
    if (result.status == 200) {
      final json = jsonDecode(result.body);
      faces = [];
      for (var face in json) {
        faces.add(FaceModel.fromJson(this, face));
      }
    }
  }

  Future<List<FaceModel>?> getFaces() async {
    if (!_facesLoaded) {
      await _loadFaces();
      _facesLoaded = true;
    }
    return faces;
  }
}
