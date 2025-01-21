import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app/models/account_model.dart';
import 'package:app/models/group_message_model.dart';
import 'package:app/models/websocket_message_model.dart';
import 'package:app/services/accounts_service.dart';
import 'package:app/services/groups_service.dart';
import 'package:flutter/widgets.dart';

class WebSocketSubscriber {
  final List<String> messageTypes;
  final AccountModel account;
  // callback will be called when there's a state change in the socket or incoming message
  final Function(WebSocket? channel, WebSocketMessage? data) callback;
  WebSocketSubscriber(this.account, this.messageTypes, this.callback);
}

class WebSocketService extends ChangeNotifier {
  static const messageTypeGroupMessage = "group_message";
  static const messageTypeGroupUpdate = "group_update";
  static const messageTypeSeenMessage = "seen_message";
  // One WebSocket per account
  final Map<AccountModel, WebSocket?> _channels = {};
  final List<WebSocketSubscriber> _subscribers = [];

  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  Future<WebSocket?> getChannel(AccountModel account) async {
    await _setupAccount(account);
    return _channels[account];
  }

  void subscribe(WebSocketSubscriber subscriber) {
    _subscribers.add(subscriber);
  }

  void unsubscribe(WebSocketSubscriber subscriber) {
    _subscribers.removeWhere((element) => element == subscriber);
  }

  void _notifySubscribers(AccountModel account, WebSocket? channel, WebSocketMessage? message) {
    // // Set "subscribers" - GroupService, NotificationService, etc...
    // if (message != null && message.type == messageTypeGroup) {
    //   GroupsService.instance.processMessage(account, GroupMessage.fromJson(message.data));
    // }
    // All other subscribers
    for (final subscriber in _subscribers) {
      if (subscriber.account != account) {
        continue;
      }
      if (message!=null && subscriber.messageTypes.contains(message!.type)) {
        subscriber.callback(channel, message);
      } else {
        subscriber.callback(channel, null);
      }
    }
  }

  Future<WebSocket?> _setupSocket(AccountModel account) async {
    Timer? pingTimer;
    Future<void> reconnect() async {
      // Stop current ping timer, if any running
      if (pingTimer != null && pingTimer!.isActive) {
        pingTimer!.cancel();
      }
      _notifySubscribers(account, null, null);
      // Is this account still valid? (or we've logged out)
      if (AccountsService.getAccounts.contains(account)) {
        Future.delayed(const Duration(seconds: 3), () async {
          print("WebSocket:reconnecting to "+account.server);
          _channels[account] = await _setupSocket(account);
          if (_channels[account] != null && await account.updateStatus()) {
            AccountsService.updated();
          }
        });
      }
    }
    int lastIDReceived = 0;
    for (final group in await GroupsService.instance.getGroupsFor(account)) {
      if (lastIDReceived < group.lastIDReceived) {
        lastIDReceived = group.lastIDReceived;
      }
    }
    final channel = await account.apiClient.connectWebSocket("/ws?since_message=$lastIDReceived");
    if (channel == null) {
      reconnect();
      return null;
    }
    channel.listen((data) {
        if (data is String && data == "pong") {
          return;
        }
        try {
          final json = jsonDecode(data);
          final message = WebSocketMessage.fromJson(json);
          print(data);
          _notifySubscribers(account, channel, message);
        } catch (e) {
          print("Invalid WS message received: $e, data: $data");
        }
      },
      onDone: () => reconnect(),
      onError: (_) => reconnect(),
    );
    _notifySubscribers(account, channel, null);
    // Start a new ping timer
    pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      channel.add("ping");
    });
    return channel;
  }

  Future<void> _setupAccount(AccountModel account) async {
    if (_channels.containsKey(account)) {
      return;
    }
    _channels[account] = await _setupSocket(account);
  }

  Future<void> reloadAccounts(AccountsService accountsService) async {
    print("ws:reloadAccounts: ${accountsService.accounts.length}");
    // Add new account connections (if any)
    for (final account in accountsService.accounts) {
      await _setupAccount(account);
    }
    // Remove connections for accounts that are no longer present
   _channels.removeWhere((account, channel) {
      if (!accountsService.accounts.contains(account)) {
        channel?.close();
        _notifySubscribers(account, null, null);
        return true;
      }
      return false;
    });
    notifyListeners();
  }

  bool isOffline(AccountModel account) {
    return _channels[account] == null;
  }
}
