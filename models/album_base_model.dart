import 'package:app/models/asset_base_model.dart';
import 'package:app/services/api_client.dart';

abstract class AlbumBaseModel {
  static const contributorCanAdd = 0;
  static const contributorViewOnly = 1;

  String name = "";
  int heroAssetID = 0;
  String subtitle = "";

  AssetBaseModel get heroImage;
  Future<List<AssetBaseModel>> getAssets();
  Future<ApiResponse> delete();
  Future<ApiResponse> save();
  String get tag;
  bool get isOwn => false;
  bool get canAddAssets => false;
  bool get isFavouriteAlbum => false;
}
