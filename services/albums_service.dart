import 'dart:convert';
import 'package:app/models/account_model.dart';
import 'package:app/models/album_base_model.dart';
import 'package:app/models/album_model.dart';
import 'package:app/services/accounts_service.dart';
import 'package:app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'listable_service.dart';

class AlbumsService extends ChangeNotifier implements ListableService {
  final List<AlbumModel> albums = [];
  bool _isInitialised = false;
  final List<Function> _onReady = [];
  AlbumsService._();
  Future<void>? _reloadAccountsFuture;

  static final AlbumsService instance = AlbumsService._();
  static List<AlbumModel> get getAlbums => instance.albums;
  static AlbumModel? getAlbum(int id, {String? accountPushToken}) {
    for (final album in instance.albums) {
      // Skip all other accounts
      if (accountPushToken != null && album.account.pushToken != accountPushToken!) {
        continue;
      }
      if (album.id == id) {
        return album;
      }
    }
    return null;
  }

  static int size() {
    return instance.albums.length;
  }

  static void onReady(Function exec) async {
    if (instance._isInitialised) {
      await exec();
      return;
    }
    instance._onReady.add(exec);
  }

  Future<AlbumModel?> createAlbum(AccountModel account, String albumName, {bool hidden = false}) async {
    final response = await account.apiClient.post("/album/create", body: jsonEncode({
      "name": albumName,
      "hidden": hidden,
    }));
    if (response.status != 200) {
      return null;
    }
    final album = AlbumModel.fromJson(account, jsonDecode(response.body));
    if (!hidden) {
      albums.insert(0, album);
    }
    return album;
  }


  static void clearAccount(AccountModel account) {
    instance.albums.removeWhere((album) => album.account == account);
  }

  static void clear() async {
    instance.albums.clear();
  }

  Future<void> reloadAccounts(AccountsService accountsService, bool force) async {
    if (force) {
      _reloadAccountsFuture = _reloadAccounts(accountsService);
    }
    return _reloadAccountsFuture;
  }
  Future<void> _reloadAccounts(AccountsService accountsService) async {
    clear();
    for (final account in AccountsService.getAccounts) {
      try {
        await AlbumsService._loadFromAccount(account);
      } catch (e) {
        print("exception for AlbumsService.loadFromAccount(account): " + account.server + ", err: " + e.toString());
      }
    }
    // onReady handlers
    _isInitialised = true;
    for (final exec in _onReady) {
      await exec();
    }
    _onReady.clear();
    _reloadAccountsFuture = null;
  }

  static Future<void> reloadAccount(AccountModel account) async {
    clearAccount(account);
    await _loadFromAccount(account);
  }

  static Future<ApiResponse> save(AlbumBaseModel album) async {
    final response = await album.save();
    if (response.status == 200) {
      instance.notifyListeners();
    }
    return response;
  }

  static Future<ApiResponse> delete(AlbumBaseModel album) async {
    final response = await album.delete();
    if (response.status == 200) {
      instance.albums.removeWhere((element) => album is AlbumModel && element.id == album.id);
      instance.notifyListeners();
    }
    return response;
  }

  static Future<void> _loadFromAccount(AccountModel account) async {
    final response = await account.apiClient.get("/album/list");
    if (response.status != 200) {
      return;
    }
    List<dynamic> parsedListJson = jsonDecode(response.body);
    for (var element in parsedListJson) {
      instance.albums.add(AlbumModel.fromJson(account, element));
    }
  }

  @override
  Future<int> addNew(AccountModel account, String name) async {
    final album = await createAlbum(account, name);
    return album!=null ? album.id : 0;
  }

  // This function returns all albums that can be added to
  @override
  List<DropdownMenuItem<int>> getItems() {
    return albums.where((a) => !a.isFavouriteAlbum && (a.isOwn || a.canAddAssets)).map((a) => DropdownMenuItem<int>(
      value: a.id,
      child: Text(a.name),
    )).toList();
  }

}
 