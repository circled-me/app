import 'dart:convert';
import 'dart:ui';

import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';

class FaceModel {

  final AssetModel asset; // Back reference to the asset
  final int id, num;
  int personId = 0;
  String personName = "";
  final int x1, y1, x2, y2;

  FaceModel(this.asset, this.id, this.num, this.personId, this.personName, this.x1, this.y1, this.x2, this.y2);
  static FaceModel fromJson(AssetModel asset, Map<String, dynamic> json) {
    print("FaceModel: $json");
    return FaceModel(asset, json["id"].toInt(), json["num"].toInt(), json["person_id"].toInt(), json["person_name"].toString(),
        json["x1"].toInt(), json["y1"].toInt(), json["x2"].toInt(), json["y2"].toInt());
  }

  double get width => (x2-x1).toDouble();
  double get height => (y2-y1).toDouble();
  double get centerX => x1 + width/2;
  double get centerY => y1 + height/2;

  double get alignX => 2*centerX/960 - 1;
  double get alignY => 2*centerY/1280 - 1;
  // Return slightly bigger rect
  Rect get rect {
    var w4 = width/4;
    var h4 = height/4;
    return Rect.fromLTWH(x1.toDouble()-w4, y1.toDouble()-h4, 6*w4, 6*h4);
  }
  // Return even bigger square
  Rect get bigSquare {
    var w2 = width/2;
    var h2 = height/2;
    if (w2 > h2) {
      h2 = w2;
    } else {
      w2 = h2;
    }
    return Rect.fromLTWH(x1.toDouble()-w2, y1.toDouble()-h2, 4*w2, 4*h2);
  }
  String get name => personName.isEmpty ? "<unknown>" : personName;
  String get tag => "FaceTag-"+asset.account.identifier+"-"+id.toString();

  Future<List<AssetModel>> getAssets() async {
    final result = await asset.account.apiClient.get("/asset/list?threshold=0.25&face_id=" + id.toString());
    if (result.status != 200) {
      return [];
    }
    List<AssetModel> assets = [];
    List<dynamic> json = jsonDecode(result.body);
    for (final j in json) {
      assets.add(AssetModel.fromAccountJson(asset.account, j));
    }
    return assets;
  }
}
