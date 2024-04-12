import 'dart:convert';
import 'package:app/models/album_base_model.dart';
import 'package:app/models/account_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/services/api_client.dart';

class AlbumModel extends AlbumBaseModel {
  static const contributorCanAdd = 0;
  static const contributorViewOnly = 1;

  final AccountModel account;
  final int id;
  final int owner;
  final int? mode;
  final bool hidden;
  final Set<int> editors;
  final Set<int> viewers;

  AlbumModel(this.account, this.id, this.owner, String name, String subtitle, int heroAssetId, this.mode, this.editors, this.viewers, this.hidden) {
    super.name = name;
    super.subtitle = subtitle;
    super.heroAssetID = heroAssetId;
  }

  static AlbumModel fromJson(AccountModel account, Map<String, dynamic> json) {
    return AlbumModel(account, json["id"], json["owner"], json["name"], json["subtitle"], json["hero_asset_id"] ?? 0, json["mode"] as int?, {}, {}, json["hidden"] ?? false);
  }

  @override
  AssetModel get heroImage => AssetModel.hero(account, heroAssetID);

  @override
  Future<List<AssetBaseModel>> getAssets() async {
    final result = await account.apiClient.get("/album/assets?album_id=" + id.toString());
    if (result.status != 200) {
      return [];
    }
    // TODO: Refresh hero image too
    List<AssetBaseModel> assets = [];
    List<dynamic> json = jsonDecode(result.body);
    for (final j in json) {
      assets.add(AssetModel.fromAccountJson(account, j));
    }
    return assets;
  }

  Future<bool> loadContributors() async {
    final result = await account.apiClient.get("/album/contributors?album_id=" + id.toString());
    if (result.status != 200) {
      return false;
    }
    viewers.clear();
    editors.clear();
    JSONObject  json = jsonDecode(result.body);
    Map<String, int> members = json["contributors"].cast<String, int>();
    for (final member in members.entries) {
      if (member.value == contributorCanAdd) {
        editors.add(int.parse(member.key));
      } else if (member.value == contributorViewOnly) {
        viewers.add(int.parse(member.key));
      }
    }
    return true;
  }

  Future<bool> saveContributors() async {
    final contributors = <String, int>{};
    for (final member in viewers) {
      contributors[member.toString()] = contributorViewOnly;
    }
    for (final member in editors) {
      contributors[member.toString()] = contributorCanAdd;
    }
    print(jsonEncode({
      "album_id": id,
      "contributors": contributors,
    }));
    final result = await account.apiClient.post("/album/contributors", body: jsonEncode({
      "album_id": id,
      "contributors": contributors,
    }));
    if (result.status != 200) {
      print("/album/contributors error ${result.status}: ${result.body}");
      return false;
    }
    return true;
  }

  @override
  Future<ApiResponse> delete() async {
    return account.apiClient.post("/album/delete", body: jsonEncode({
      "album_id": id,
    }));
  }
  @override
  Future<ApiResponse> save() async {
    return account.apiClient.post("/album/save", body: jsonEncode({
      "id": id,
      "name": name,
      "hero_asset_id": heroAssetID,
    }));
  }
  Future<ApiResponse> getShareInfo(int expires, int hideOriginal) async {
    return account.apiClient.get("/album/share?album_id=" + id.toString() + "&expires=" + expires.toString() + "&hide_original=" + hideOriginal.toString());
  }
  Future<ApiResponse> addContributor(int userId, mode) async {
    return account.apiClient.post("/album/contributor", body: jsonEncode({
      "album_id": id,
      "user_id": userId,
      "mode": mode,
    }));
  }
  @override
  String get tag => "AlbumTag-"+account.identifier+"-"+id.toString();
  @override
  bool get isOwn => owner == account.userID;
  @override
  bool get canAddAssets => mode == null || mode == contributorCanAdd;
  @override
  bool get isFavouriteAlbum => id == 0;
}
