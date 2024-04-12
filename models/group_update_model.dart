
import 'package:app/services/api_client.dart';

class GroupUpdate {
  static const valueNew = "new";
  static const valueLeft = "left";
  static const valueNameChanged = "name_change";

  final String value;
  final int groupID;
  final String title;
  final String body;
  final String name;
  GroupUpdate(this.value, this.groupID, this.title, this.body, this.name);

  static GroupUpdate fromJson(Map<String, dynamic> json) {
    return GroupUpdate(
        json["value"] as String,
        json["group_id"] as int,
        json["title"] as String,
        json["body"] as String,
        json["name"] as String
    );
  }

  JSONObject toJson() {
    return {
      "value": value,
      "group_id": groupID,
      "title": title,
      "body": body,
      "name": name,
    };
  }

  bool hasLeft(int gid) => value == valueLeft && groupID == gid;
  bool hasNameChanged(int gid) => value == valueNameChanged && groupID == gid;
  bool hasEntered(int gid) => value == valueNew && groupID == gid;
  get isNew => value == valueNew;
}
