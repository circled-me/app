
import 'package:app/services/api_client.dart';

class GroupMessageReaction {
  final int id;
  final int userID;
  final int groupID;
  final String reaction;
  GroupMessageReaction(this.id, this.userID, this.groupID, this.reaction);

  static GroupMessageReaction fromJson(Map<String, dynamic> json) {
    return GroupMessageReaction(
        json["id"] as int,
        json["user_id"] as int,
        json["group_id"] as int,
        json["reaction"] as String
    );
  }

  JSONObject toJson() {
    return {
      "id": id,
      "user_id": userID,
      "group_id": groupID,
      "reaction": reaction,
    };
  }
}
