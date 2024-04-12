import 'dart:convert';

import 'package:app/models/group_message_model.dart';
import 'package:app/models/group_model.dart';
import 'package:app/models/websocket_message_model.dart';
import 'package:app/services/groups_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../models/album_model.dart';
import '../models/asset_model.dart';
import '../services/accounts_service.dart';
import '../services/albums_service.dart';
import '../services/listable_service.dart';
import '../widget/select_add_album_widget.dart';

class Group {
  static void share(String text) async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    GroupModel? group;
    final toShareWith = await showDialog<GroupModel?>(
      context: rootContext,
      builder: (context) => AlertDialog(
        title: const Text("Share with"),
        content: FutureBuilder<List<GroupModel>>(
          future: GroupsService.instance.getGroups(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final groups = snapshot.data!;
            return StatefulBuilder(builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<GroupModel>(
                      isDense: false,
                      value: group,
                      hint: const Text("Select group..."),
                      onChanged: (newValue) => setState(() {
                        group = newValue;
                      }),
                      // TODO: Change this to GroupModel (to have access to account)
                      items: groups.map((g) => DropdownMenuItem<GroupModel>(child: Text(g.title()), value: g,)).toList(),
                    ),
                  ),
                ],
              );
            },);
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(group),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (toShareWith==null) {
      return;
    }
    final wsChannel = await WebSocketService.instance.getChannel(toShareWith!.account);
    if (wsChannel == null) {
      Toast.show(msg: "Cannot send message to group. Connection unavailable");
      return;
    }
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final message = GroupMessage(0, toShareWith!.id, stamp, 0, 0, "", text);
    wsChannel!.add(jsonEncode(WebSocketMessage(WebSocketService.messageTypeGroupMessage, stamp, message)));
  }
}
