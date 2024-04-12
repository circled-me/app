
import 'package:app/models/album_base_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/external_asset_model.dart';
import 'package:app/services/api_client.dart';

class ExternalAlbumModel extends AlbumBaseModel {
  final String link;
  final String cacheID;
  final List<AssetBaseModel> assets = [];
  AssetBaseModel? heroAsset = null;

  ExternalAlbumModel(this.cacheID, this.link, JSONObject json) {
    name = json["name"];
    // subtitle = json["subtitle"];
    subtitle = json["ownerName"];
    heroAssetID = json["heroAssetID"];
    List<dynamic> assetsJson = json["assets"];
    for (final aj in assetsJson) {
      final a = ExternalAssetModel.from(link, aj);
      assets.add(a);
      if (a.id == heroAssetID) {
        heroAsset = a;
      }
    }
  }

  @override
  Future<ApiResponse> delete() async {
    return const ApiResponse(666, "", null);
  }

  @override
  Future<List<AssetBaseModel>> getAssets() async {
    return assets;
  }

  @override
  AssetBaseModel get heroImage => heroAsset ?? assets.first;

  @override
  Future<ApiResponse> save() async {
    return const ApiResponse(666, "", null);
  }

  @override
  String get tag => "ExternalAlbum-" + cacheID;
}
