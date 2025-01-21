
import 'package:app/services/api_client.dart';

class SeenMessage {
  final int id;
  final int groupID;
  final int userID;
  SeenMessage(this.id, this.groupID, this.userID);

  static SeenMessage fromJson(Map<String, dynamic> json) {
    return SeenMessage(
        json["id"] as int,
        json["group_id"] as int,
        json["user_id"] as int,
    );
  }

  JSONObject toJson() {
    return {
      "id": id,
      "group_id": groupID,
      "user_id": userID,
    };
  }
}
