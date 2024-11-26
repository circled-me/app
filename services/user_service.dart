import 'dart:collection';
import 'dart:convert';
import 'package:app/models/account_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/models/face_model.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final AccountModel account;
  final List<UserModel> users = [];
  final List<FaceModel> people = [];
  final Map<int, UserModel> userMap = {};
  late bool _peopleLoaded = false;

  UserService(this.account);

  static Map<AccountModel, UserService> instances = HashMap();
  static Future<UserService> forAccount(AccountModel account) async {
    bool isNew = false;
    final result = instances.putIfAbsent(account, () {
      isNew = true;
      return UserService(account);
    });
    if (isNew) {
      await result.loadFromAccount();
    }
    return result;
  }

  void clear() async {
    users.clear();
    userMap.clear();
  }

  UserModel? find(int id) {
    return userMap[id];
  }

  Future<void> loadFromAccount() async {
    print("loading users list /user/list");
    final response = await account.apiClient.get("/user/list");
    if (response.status != 200) {
      return;
    }
    List<dynamic> parsedListJson = jsonDecode(response.body);
    for (var element in parsedListJson) {
      final u = UserModel.fromJson(account, element);
      users.add(u);
      userMap[u.id] = u;
    }
    notifyListeners();
  }

  @override
  Future<int> addNew(String name) async {
    return 0; // not implemented
  }

  @override
  List<DropdownMenuItem<int>> getItems() {
    return users.map((a) => DropdownMenuItem<int>(
      value: a.id,
      child: Text(a.name),
    )).toList();
  }

  Future<void> _loadPeople() async {
    final result = await account.apiClient.get("/faces/people");
    if (result.status != 200) {
      print("Failed to load people for asset: "+result.body);
      return;
    }
    print("Loaded people: "+result.body);
    final json = jsonDecode(result.body);
    people.clear();
    for (var face in json) {
      // Load the asset for the face
      final asset = AssetModel(account, face["asset_id"] as int, "", 0, 0, AssetBaseModel.typeImage, "", null, null, "", 0);
      people.add(FaceModel.fromJson(asset, face));
    }
  }

  Future<List<FaceModel>> getPeople() async {
    if (!_peopleLoaded) {
      await _loadPeople();
      _peopleLoaded = true;
    }
    return people;
  }

  void resetPeople() {
    _peopleLoaded = false;
  }
}
 