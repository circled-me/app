import 'dart:convert';

import 'package:app/models/group_message_model.dart';
import 'package:app/models/group_model.dart';
import 'package:app/models/websocket_message_model.dart';
import 'package:app/services/groups_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';
import 'package:app/main.dart';

class Group {
  static void share(String text) async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    GroupModel? group;
    final toShareWith = await showDialog<GroupModel?>(
      context: rootContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
    final wsChannel = await WebSocketService.instance.getChannel(toShareWith.account);
    if (wsChannel == null) {
      Toast.show(msg: "Cannot send message to group. Connection unavailable");
      return;
    }
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final message = GroupMessage(0, toShareWith.id, stamp, 0, 0, "", text, 0, 0);
    wsChannel.add(jsonEncode(WebSocketMessage(WebSocketService.messageTypeGroupMessage, stamp, message)));
  }
}
