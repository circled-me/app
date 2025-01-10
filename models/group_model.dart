import 'dart:convert';

import 'package:app/models/account_model.dart';
import 'package:app/models/group_message_model.dart';
import 'package:app/models/group_user_model.dart';
import 'package:app/services/groups_service.dart';
import 'package:app/storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class GroupModel {
  final AccountModel account;
  final int id;
  String name;
  String colour;
  bool favourite;
  int lastReadID = -1;
  bool allMessagesLoaded = false;
  bool _isNew = false;
  final bool isAdmin;
  final List<GroupMessage> messages = [];
  final List<GroupUser> members;
  late Storage _storage;
  String draftMessage = "";

  GroupModel(this.account, this.id, this.name, this.colour, this.favourite, this.isAdmin, this.members) {
    _storage = Storage(identifier);
  }

  static GroupModel fromJson(AccountModel account, Map<String, dynamic> json) {
    return GroupModel(account, json["id"], json["name"], json["colour"], json["favourite"], json["is_admin"],
        (json["members"] as List<dynamic>).map((e) => GroupUser.fromJson(e)).toList());
  }

  get identifier => account.identifier + "#" + id.toString();
  get isNew => _isNew;
  void setNew(bool n) => _isNew = n;
  void clearNew() {
    _isNew = false;
    GroupsService.instance.notifyListeners();
  }
  get hasUnread {
    if (_isNew) {
      return true;
    }
    if (messages.isEmpty || messages.last.id == lastReadID || lastReadID == -1) {
      return false;
    }
    // Check if all unread messages are ours
    for (int i=messages.length-1; i>=0 && messages[i].id>lastReadID; --i) {
      if (messages[i].userID != account.userID) {
        return true;
      }
    }
    return false;
  }
  get lastIDReceived => messages.isNotEmpty ? messages.last.id : 0;
  get tag => "GroupTag-"+account.identifier+"-"+id.toString();

  Future<ApiResponse> getCallPath() async {
    return account.apiClient.get("/group/video-link?id=$id");
  }

  String messageTime() {
    if (messages.isEmpty) {
      return "";
    }
    final m = messages.last;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(m.serverStamp);
    DateFormat df;
    if (now - m.serverStamp > 365*86400*1000) {
      df = DateFormat("yyyy");
    } else if (now - m.serverStamp > 6*86400*1000) {
      df = DateFormat("d MMM");
    } else if (now - m.serverStamp > 86400*1000) {
      df = DateFormat("EEE");
    } else {
      df = DateFormat("HH:mm");
    }
    return df.format(dt);
  }

  String messagePreview() {
    if (messages.isEmpty) {
      if (members.length == 2 && name == "") {
        return "Start chatting";
      }
      return userListPreview();
    }
    final m = messages.last;
    final who = account.userID == m.userID ? "Me" : m.userName;
    final maxLen = 25 - who.length;
    if (m.content.length > maxLen) {
      return who + ": " + m.content.substring(0, maxLen)+"...";
    }
    return who + ": " + m.content;
  }

  String title() {
    if (name == "") {
      return userListPreview();
    }
    return name;
  }

  String subtitle() {
    if (name == "") {
      return members.length==2 ? "private chat" : (!isAdmin || !account.canCreateGroups() ? "group chat" : "edit to set name");
    }
    return userListPreview();
  }

  String userListPreview() {
    String result = "";
    for (final member in members) {
      if (account.userID == member.id) {
        continue;
      }
      if (result.length > 30) {
        return result+"...";
      }
      result += (result.isNotEmpty?", ":"") + member.name;
    }
    return result;
  }

  JSONObject toJson() {
    return {
      "id": id,
      "name"  : name,
      "colour": colour,
      "favourite": favourite,
      "members": members,
    };
  }

  JSONObject _forLocalStorage() {
    return {
      "lastReadID": lastReadID,
      "messages": messages,
      "draftMessage": draftMessage,
    };
  }

  Future<void> deleteLocalData() async {
    await _storage.delete();
  }

  Future<void> loadLocalData() async {
    final msgString = await _storage.read();
    if (msgString == null) {
      return;
    }
    try {
      Map<String, dynamic> jsonData = jsonDecode(msgString);
      lastReadID = jsonData["lastReadID"] as int;
      draftMessage = jsonData["draftMessage"] as String;
      List<dynamic> jsonList = jsonData["messages"];
      for (final e in jsonList) {
        messages.add(GroupMessage.fromJson(e));
      }
    } catch (e) {
      deleteLocalData(); // Will reload everything from server
    }
  }

  Future<void> saveLastReadMessage(int id) async {
    lastReadID = id;
    await saveLocalData();
  }

  Future<void> saveDraftMessage(String message) async {
    draftMessage = message;
    await saveLocalData();
  }

  Future<void> saveLocalData() async {
    if (lastReadID == -1) {
      lastReadID = 0;
    }
    final msgsAsString = jsonEncode(_forLocalStorage());
    await _storage.write(msgsAsString);
  }

  Future<bool> saveRemote() async {
    final result = await account.apiClient.post("/group/save", body: jsonEncode(this));
    if (result.status != 200) {
      print("/group/save error: "+result.status.toString() +":" + result.body);
      return false;
    }
    return true;
  }

  Future<bool> deleteRemote() async {
    final result = await account.apiClient.post("/group/delete", body: jsonEncode({
      "id": id
    }));
    if (result.status != 200) {
      print("/group/delete error: "+result.status.toString() +":" + result.body);
      return false;
    }
    return true;
  }

  Color get getColour {
    if (colour.length != 6) {
      colour = '673ab7'; // dark purplish blue
    }
    int r = int.parse(colour.substring(0,2), radix: 16);
    int g = int.parse(colour.substring(2,4), radix: 16);
    int b = int.parse(colour.substring(4,6), radix: 16);
    return Color.fromARGB(255, r, g, b);
  }

  void setColorFromColor(Color c) {
    colour =  c.red.toRadixString(16).padLeft(2, '0') +
              c.green.toRadixString(16).padLeft(2, '0') +
              c.blue.toRadixString(16).padLeft(2, '0');
  }
}
