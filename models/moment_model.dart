import 'dart:convert';

import 'package:app/models/account_model.dart';
import 'package:app/models/album_base_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/services/api_client.dart';
import 'package:flutter/material.dart';

class MomentModel extends AlbumBaseModel {
  final AccountModel account;
  final String places;
  final String name;
  final String subtitle;
  final int heroAssetId;
  final int start;
  final int end;

  MomentModel(this.account, this.places, this.name, this.subtitle, this.heroAssetId, this.start, this.end);

  static MomentModel fromJson(AccountModel account, Map<String, dynamic> json) {
    return MomentModel(account, json["places"], json["name"], json["subtitle"], json["hero_asset_id"] ?? 0, json["start"], json["end"]);
  }

  AssetModel get heroImage => AssetModel.hero(account, heroAssetId);
  @override
  Future<List<AssetBaseModel>> getAssets() async {
    final result = await account.apiClient.get("/moment/assets", params: {
      "places": places,
      "start": start.toString(),
      "end": end.toString(),
    });
    List<AssetBaseModel> assets = [];
    List<dynamic> json = jsonDecode(result.body);
    for (final j in json) {
      assets.add(AssetModel.fromAccountJson(account, j));
    }
    return assets;
  }
  String get tag => "MomentTag-"+places.toString()+"-"+start.toString()+"-"+end.toString();

  @override
  Future<ApiResponse> delete() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse> save() {
    throw UnimplementedError();
  }
}
