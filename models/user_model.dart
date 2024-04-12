import 'dart:convert';

import 'package:app/models/account_model.dart';
import 'package:app/services/api_client.dart';

class UserModel {
  static const permissionAdmin = 1;
  static const permissionPhotoUpload = 2;
  static const permissionCanCreateGroups = 3;
  static const permissionPhotoBackup = 5;

  final AccountModel account;
  final int id;
  String name;
  String email;
  int bucket;
  int quota; // in MB, 0 == unlimited
  List<int> permissions;

  UserModel(this.account, this.id, this.name, this.email, this.bucket, this.quota, this.permissions);
  UserModel.from(this.account, {this.id=0, this.name="", this.email="", this.bucket=0, this.quota=0, this.permissions=const[]});
  UserModel.empty(this.account) : id=0, name="", email="", permissions=[], bucket=0, quota=0;

  static UserModel fromJson(AccountModel account, Map<String, dynamic> json) {
    return UserModel(account, json["id"], json["name"], json["email"], json["bucket"], json["quota"], json["permissions"].cast<int>());
  }

  JSONObject toJson() {
    return {
      "id": id,
      "name" : name,
      "email": email,
      "bucket": bucket,
      "quota": quota,
      "permissions": permissions,
    };
  }

  Future<ApiResponse> save() async {
    return account.apiClient.post("/user/save", body: jsonEncode(this));
  }
  Future<ApiResponse> delete() async {
    return account.apiClient.post("/user/delete", body: jsonEncode(this));
  }
  Future<ApiResponse> reinvite() async {
    return account.apiClient.post("/user/reinvite", body: jsonEncode(this));
  }
}
