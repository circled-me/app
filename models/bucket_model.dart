import 'dart:convert';

import 'package:app/models/account_model.dart';
import 'package:app/services/api_client.dart';

class BucketModel {
  static const storageTypeFile = 0;
  static const storageTypeS3 = 1;
  static const Map<String, String> assetPathPatterns = {
    "" : "Asset Path Format",
    "<id>" : "1.jpg (1 is asset ID)",
    "<id>-<name>" : "1-ImageName.jpg",
    "<year>/<id>" : "2023/1.jpg (2023 is year)",
    "<year>/<id>-<name>" : "2023/1-ImageName.jpg",
    "<year>/<month>/<id>" : "2023/10/1.jpg (10 is month)",
    "<year>/<month>/<id>-<name>" : "2023/10/1-ImageName.jpg",
    "<year>/<Month>/<id>" : "2023/October/1.jpg",
    "<year>/<Month>/<id>-<name>" : "2023/October/1-ImageName.jpg",
  };
  final AccountModel account;
  int id, storageType;
  String name, path, endpoint, assetPathPattern, s3Key, s3Secret, s3Region, s3Encryption;

  BucketModel(this.account, this.id, this.name, this.path, this.storageType, this.endpoint, this.s3Key,
              this.s3Secret, this.s3Region, this.s3Encryption, this.assetPathPattern);

  BucketModel.empty(this.account) : id=0, name="", path="", storageType=BucketModel.storageTypeFile,
                                    endpoint="", s3Key="", s3Secret="", s3Region="", s3Encryption="", assetPathPattern="";

  static BucketModel fromJson(AccountModel account, Map<String, dynamic> json) {
    return BucketModel(account, json["id"], json["name"], json["path"], json["storage_type"],
                        json["endpoint"], json["s3key"], json["s3secret"],
                        json["s3region"], json["s3encryption"], json["asset_path_pattern"] ?? "");
  }

  JSONObject toJson() {
    return {
      "id": id,
      "name"  : name,
      "path": path,
      "storage_type": storageType,
      "endpoint": endpoint,
      "s3key": s3Key,
      "s3secret": s3Secret,
      "s3region": s3Region,
      "s3encryption": s3Encryption,
      "asset_path_pattern": assetPathPattern,
    };
  }

  Future<ApiResponse> save() async {
    return account.apiClient.post("/bucket/save", body: jsonEncode(this));
  }

  // Does not exist remotely yet
  Future<ApiResponse> delete() async {
    return account.apiClient.post("/bucket/delete", body: jsonEncode({
      "id": id,
    }));
  }
}
