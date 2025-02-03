
import 'package:app/services/api_client.dart';

class GroupMessageReaction {
  final int userID;
  final String reaction;
  GroupMessageReaction(this.userID, this.reaction);

  static GroupMessageReaction fromJson(Map<String, dynamic> json) {
    return GroupMessageReaction(
        json["user_id"] as int,
        json["reaction"] as String
    );
  }

  JSONObject toJson() {
    return {
      "user_id": userID,
      "reaction": reaction,
    };
  }
}
