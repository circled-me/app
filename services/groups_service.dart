import 'dart:convert';
import 'dart:io';
import 'package:app/helpers/toast.dart';
import 'package:app/models/account_model.dart';
import 'package:app/models/group_message_model.dart';
import 'package:app/models/group_model.dart';
import 'package:app/models/group_update_model.dart';
import 'package:app/models/group_user_model.dart';
import 'package:app/models/seen_message_model.dart';
import 'package:app/services/accounts_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/storage.dart';
import 'package:flutter/material.dart';
import 'listable_service.dart';

class GroupsService extends ChangeNotifier implements ListableService {
  final List<GroupModel> _groups = [];
  final Map<AccountModel, WebSocketSubscriber> _wsSubs = {};
  final Map<AccountModel, WebSocket?> _wsChannels = {};
  Future<List<GroupModel>>? _groupLoader;
  Function(GroupMessage)? savedMessageReceiver;

  GroupsService._();
  static final GroupsService instance = GroupsService._();

  Future<GroupModel?> createGroup(AccountModel account, List<GroupUser> members) async {
    final response = await account.apiClient.post("/group/create", body: jsonEncode({
      "members": members
    }));
    if (response.status != 200) {
      print("Error ${response.status} creating group: ${response.body}");
      return null;
    }
    final group = GroupModel.fromJson(account, jsonDecode(response.body));
    _groups.add(group);
    notifyListeners();
    return group;
  }

  int numUnreadGroups() {
    int result = 0;
    for (final g in _groups) {
      if (g.hasUnread) {
        result++;
      }
    }
    return result;
  }

  static Future<bool> save(GroupModel group) async {
    if (!await group.saveRemote()) {
      return false;
    }
    instance.notifyListeners();
    return true;
  }

  static Future<bool> delete(GroupModel group) async {
    if (!await group.deleteRemote()) {
      return false;
    }
    instance._groups.remove(group);
    instance.notifyListeners();
    return true;
  }

  void reloadAccounts(AccountsService accountService) async {
    // if (_groupLoader != null) {
    //   await _groupLoader;
    // }
    _groupLoader = _reloadGroups(accountService);
    await _groupLoader;
    notifyListeners();
  }

  Future<List<GroupModel>> getGroups() async {
    if (_groupLoader == null) {
      return [];
    }
    return _groupLoader!;
  }

  Future<List<GroupModel>> getGroupsFor(AccountModel account) async {
    return (await getGroups()).
            where((g) => g.account==account).
            toList(growable: false);
  }

  Future<List<GroupModel>> _reloadGroups(AccountsService accountService) async {
    print("_reloadGroups");
    // Remove references to logged out accounts
    _wsSubs.removeWhere((account, sub) {
      final removed = !accountService.accounts.contains(account);
      if (removed) {
        WebSocketService.instance.unsubscribe(sub);
      }
      return removed;
    });
    _wsChannels.removeWhere((account, ws) => !accountService.accounts.contains(account));
    _groups.removeWhere((group) => !accountService.accounts.contains(group.account));
    // Load newly added accounts
    for (final account in accountService.accounts) {
      if (_wsSubs[account] == null) {
        await _loadFromAccount(account);
      }
    }
    _sortGroups();
    return _groups;
  }

  void _sortGroups() {
    _groups.sort((a, b) {
      // final au = a.hasUnread;
      // final bu = b.hasUnread;
      // if (au != bu) {
      //   return au ? -1 : 1;
      // }
      if (a.favourite != b.favourite) {
        return a.favourite ? -1 : 1;
      }
      return b.lastIDReceived.compareTo(a.lastIDReceived);
    });
  }

  Future<void> reSortGroups() async {
    await _groupLoader;
    _sortGroups();
    _groupLoader = Future(() => _groups);
    notifyListeners();
  }

  Future<void> processMessage(AccountModel account, GroupMessage groupMessage) async {
    for (final group in _groups) {
      if (group.id == groupMessage.groupID && group.account == account) {
        group.messages.add(groupMessage);
        group.saveLocalData();
        if (savedMessageReceiver != null) {
          savedMessageReceiver!(groupMessage);
        }
        // Re-arrange the order of groups so unread messages are on top
        await reSortGroups();
        break;
      }
    }
  }

  Future<void> processSeen(AccountModel account, SeenMessage seenMessage) async {
    for (final group in _groups) {
      if (group.id == seenMessage.groupID && group.account == account) {
        print("updateMemberSeenMessage: ${seenMessage.userID}, ${seenMessage.id}");
        group.updateMemberSeenMessage(seenMessage.userID, seenMessage.id);
        // group.saveLocalData();
        break;
      }
    }
  }

  Future<void> _reloadGroupsFor(AccountModel account) async {
    final response = await account.apiClient.get("/group/list");
    if (response.status != 200) {
      return;
    }
    List<dynamic> parsedListJson = jsonDecode(response.body);
    // final tmpLoaders = <Future>[];
    final newGroups = <GroupModel>[];
    for (var element in parsedListJson) {
      // tmpLoaders.add(Future(() async {
      final group = GroupModel.fromJson(account, element);
      await group.loadLocalData();
      await group.saveLocalData();
      newGroups.add(group);
      // }));
    }
    _groups.removeWhere((g) => g.account == account);
    _groups.addAll(newGroups);
    // Wait for all future loaders to finish
    // for (final loader in tmpLoaders) {
    //   await loader;
    // }
  }

  Future<void> _loadFromAccount(AccountModel account) async {
    await _reloadGroupsFor(account);
    // TODO: Delete local messages (maybe separate method after logout?)
    final wsSub = WebSocketSubscriber(account,
      [WebSocketService.messageTypeGroupMessage, WebSocketService.messageTypeGroupUpdate, WebSocketService.messageTypeSeenMessage],
      (channel, message) async {

      _wsChannels[account] = channel;
      if (message == null) {
        return;
      }
      if (message.type == WebSocketService.messageTypeGroupMessage) {
        processMessage(account, GroupMessage.fromJson(message.data));
        notifyListeners();
      } else if (message.type == WebSocketService.messageTypeGroupUpdate) {
        final update = GroupUpdate.fromJson(message.data);
        await _reloadGroupsFor(account);
        if (update.isNew) {
          for (final g in _groups) {
            if (update.hasEntered(g.id)) {
              g.setNew(true);
            } else if (update.hasNameChanged(g.id)) {
              g.name = update.name;
            }
          }
        }
        notifyListeners();
        if (update.title != "") {
          Toast.show(msg: update.title, timeInSecForIosWeb: 3);
        }
      } else if (message.type == WebSocketService.messageTypeSeenMessage) {
        processSeen(account, SeenMessage.fromJson(message.data));
        notifyListeners();
      }
    });
    WebSocketService.instance.subscribe(wsSub!);
    _wsSubs[account] = wsSub;
  }

  @deprecated
  @override
  Future<int> addNew(AccountModel account, String name) async {
    return 0;
  }

  @override
  List<DropdownMenuItem<int>> getItems() {
    return _groups.map((a) => DropdownMenuItem<int>(
      value: a.id,
      child: Text(a.name),
    )).toList();
  }

}
 