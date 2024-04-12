
import 'package:app/services/api_client.dart';

class GroupUser {
  final int id;
  final String name; // TODO: to be removed
  final bool isAdmin;
  GroupUser(this.id, this.name, this.isAdmin);

  static GroupUser fromJson(Map<String, dynamic> json) {
    return GroupUser(
        json["id"] as int,
        json["name"] as String,
        json["is_admin"] as bool,
    );
  }

  JSONObject toJson() {
    return {
      "id": id,
      "name": name,
      "is_admin": isAdmin,
    };
  }
}
