import 'dart:convert';
import 'package:app/models/account_model.dart';
import 'package:app/models/album_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/models/tag_model.dart';
import 'package:app/services/accounts_service.dart';
import 'package:app/services/api_client.dart';
import 'package:app/services/tag_service.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'listable_service.dart';

class AssetsService extends ChangeNotifier {
  AssetsService._();
  final Map<AccountModel, List<AssetModel>> _assets = {};
  final Map<AccountModel, Future<List<AssetModel>>> _assetsPending = {};
  final Map<AccountModel, List<TagModel>> _tags = {};
  final Map<AccountModel, Future<List<TagModel>>> _tagsPending = {};
  static final AssetsService instance = AssetsService._();

  Future<List<AssetModel>> getAssets(AccountModel account) async {
    // Is there a pending reload for this account?
    if (_assetsPending.containsKey(account) && _assetsPending[account] != null) {
      print("pending load of assets...");
      return _assetsPending[account]!;
    }
    if (_assets.containsKey(account) && _assets[account] != null && _assets[account]!.isNotEmpty) {
      print("from loaded assets...");
      return _assets[account]!;
    }
    print("new load of assets...");
    _tagsPending[account] = _fetchTags(account); // TODO: Change?
    return _assetsPending[account] = _fetchAssets(account);
  }

  Future<List<TagModel>> getTags(AccountModel account) async {
    // Is there a pending reload for this account?
    if (_tagsPending.containsKey(account) && _tagsPending[account] != null) {
      print("pending load of tags...");
      return _tagsPending[account]!;
    }
    if (_tags.containsKey(account) && _tags[account] != null && _tags[account]!.isNotEmpty) {
      print("from loaded tags...");
      return _tags[account]!;
    }
    print("new load of tags...");
    return _tagsPending[account] = _fetchTags(account);
  }

  Future<List<TagModel>> _fetchTags(AccountModel account) async {
    final result = await account.apiClient.get("/asset/tags");
    if (result.status != 200) {
      return [];
    }
    final List json = jsonDecode(result.body);
    List<TagModel> tags = [];
    for (final t in json) {
      tags.add(TagModel.fromJson(t));
    }
    return tags;
  }

  Future<List<AssetModel>> _fetchAssets(AccountModel account) async {
    final result = await account.apiClient.get("/asset/list");
    if (result.status != 200) {
      return [];
    }
    _assets[account] = [];
    List<dynamic> json = jsonDecode(result.body);
    for (final j in json) {
      _assets[account]!.add(AssetModel.fromAccountJson(account, j));
    }
    // Clear this as it is not pending anymore
    _assetsPending.remove(account);
    return _assets[account]!;
  }

  Future<void> reloadAccounts(AccountsService accountsService) async {
    for (final account in accountsService.accounts) {
      _assetsPending[account] = _fetchAssets(account);
      _tagsPending[account] = _fetchTags(account);
    }
  }

  void addAsset(AssetModel asset) {
    if (_assets[asset.account] == null) {
      _assets[asset.account] = [];
    }
    _assets[asset.account]!.add(asset);
    notifyListeners();
  }

  void removeAsset(AssetModel asset) {
    if (_assets[asset.account] == null) {
      return;
    }
    _assets[asset.account]!.removeWhere((element) {
      if (element.id == asset.id) {
      }
      return element.id == asset.id;
    });
    notifyListeners();
  }
}
 