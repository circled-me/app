
import 'package:app/services/api_client.dart';

class GroupUser {
  final int id;
  final String name; // TODO: to be removed
  final bool isAdmin;
  late int lastSeenMessageId;
  GroupUser(this.id, this.name, this.isAdmin, this.lastSeenMessageId);

  static GroupUser fromJson(Map<String, dynamic> json) {
    return GroupUser(
        json["id"] as int,
        json["name"] as String,
        json["is_admin"] as bool,
        json["seen_message"] != null ? json["seen_message"] as int : 0
    );
  }

  JSONObject toJson() {
    return {
      "id": id,
      "name": name,
      "is_admin": isAdmin,
      "seen_message": lastSeenMessageId
    };
  }
}
