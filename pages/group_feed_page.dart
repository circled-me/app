import 'dart:convert';
import 'dart:io';
import 'package:app/app_consts.dart';
import 'package:app/models/group_message_model.dart';
import 'package:app/models/group_message_reaction_model.dart';
import 'package:app/models/group_update_model.dart';
import 'package:app/models/group_user_model.dart';
import 'package:app/models/seen_message_model.dart';
import 'package:app/models/websocket_message_model.dart';
import 'package:app/services/groups_service.dart';
import 'package:app/services/user_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/widget/empty_info_widget.dart';
import 'package:app/widget/giphy_widget.dart';
import 'package:app/widget/message_input_widget.dart';
import 'package:app/widget/multi_user_widget.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:app/helpers/toast.dart';
import 'package:fluttertoast/fluttertoast.dart' show ToastGravity;
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/group_model.dart';
import 'package:flutter/material.dart';
import 'groups_page.dart';


class GroupFeedPage extends StatefulWidget {
  static const route = "/group";
  final GroupModel groupModel;
  const GroupFeedPage({Key? key, required this.groupModel}) : super(key: key);

  @override
  State<GroupFeedPage> createState() => _GroupFeedPageState();
}

class _GroupFeedPageState extends State<GroupFeedPage> with AutomaticKeepAliveClientMixin<GroupFeedPage> {
  @override
  bool get wantKeepAlive => true;

  // Constants
  static const kFontSize = 17.0;

  static const kOtherPersonMessageColor = Color(0xfff0f0f0);

  static const kSmoothEdge = Radius.circular(16.0);
  static const kSharpEdge = Radius.circular(3.0);
  static const kSmoothEdgeReply = Radius.circular(10.0);
  static const kMainFontStyleGrey = TextStyle(color: Colors.black54, fontSize: kFontSize);
  static const kSecondaryFontStyle = TextStyle(color: Colors.grey, fontSize: 14);
  static const kReplyToFontStyle = TextStyle(color: Colors.grey, fontSize: 12);
  static const kReactionBiggerFontStyle = TextStyle(fontSize: 25);

  static const kBordersAll = BorderRadius.all(kSmoothEdge);
  static const kBordersAllReply = BorderRadius.all(kSmoothEdgeReply);
  static const kBordersSharpBottomRight = BorderRadius.only(topLeft: kSmoothEdge, topRight: kSmoothEdge, bottomLeft: kSmoothEdge, bottomRight: kSharpEdge);
  static const kBordersSharpTopRight = BorderRadius.only(topLeft: kSmoothEdge, topRight: kSharpEdge, bottomLeft: kSmoothEdge, bottomRight: kSmoothEdge);
  static const kBordersSharpRight = BorderRadius.only(topLeft: kSmoothEdge, topRight: kSharpEdge, bottomLeft: kSmoothEdge, bottomRight: kSharpEdge);
  static const kBordersSharpBottomLeft = BorderRadius.only(topLeft: kSmoothEdge, topRight: kSmoothEdge, bottomLeft: kSharpEdge, bottomRight: kSmoothEdge);
  static const kBordersSharpTopLeft = BorderRadius.only(topLeft: kSharpEdge, topRight: kSmoothEdge, bottomLeft: kSmoothEdge, bottomRight: kSmoothEdge);
  static const kBordersSharpLeft = BorderRadius.only(topLeft: kSharpEdge, topRight: kSmoothEdge, bottomLeft: kSharpEdge, bottomRight: kSmoothEdge);

  static const kReactions = [
    PopupMenuItem(
      value: 0,
      child: Center(child: Text("Reply")),
    ),
    PopupMenuItem(
      value: 1,
      child: Center(child: Text("Copy")),
    ),
    PopupMenuItem(
      value: "❤️",
      child: Center(child: Text("❤️", style: kReactionBiggerFontStyle)),
    ),
    PopupMenuItem(
      value: "👍",
      child: Center(child: Text("👍", style: kReactionBiggerFontStyle)),
    ),
    PopupMenuItem(
      value: "😂",
      child: Center(child: Text("😂", style: kReactionBiggerFontStyle)),
    ),
    PopupMenuItem(
      value: "😮",
      child: Center(child: Text("😮", style: kReactionBiggerFontStyle)),
    ),
    PopupMenuItem(
      value: "😢",
      child: Center(child: Text("😢", style: kReactionBiggerFontStyle)),
    ),
    PopupMenuItem(
      value: "😡",
      child: Center(child: Text("😡", style: kReactionBiggerFontStyle)),
    ),
  ];

  final TextEditingController groupNameCtrl = TextEditingController();
  final TextEditingController messageCtrl = TextEditingController();
  final scrollController = ScrollController();
  final List<List<GroupMessage>> messageClusters = [];
  WebSocket? wsChannel;
  WebSocketSubscriber? _wsSub;
  late Future<List<GroupMessage>> _futureMessages;
  String lastEnteredValue = "";
  late Future<UserService> _userServiceFuture;
  UserService? _userService;
  GroupMessage? replyTo;

  void _addMessage(GroupMessage gm) {
    // No messages or last message was more than 5 minutes ago, or from a different person...
    if (messageClusters.isEmpty ||
        gm.userID != messageClusters.last.first.userID ||
        gm.serverStamp - messageClusters.last.first.serverStamp > 3*60000) {
      // Create new cluster
      messageClusters.add([gm]);
    } else {
      // No - add to the last cluster
      messageClusters.last.add(gm);
    }
  }

  void seenAck(GroupMessage message) {
    widget.groupModel.saveLastReadMessage(message);
    if (wsChannel == null) {
      return;
    }
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final ack = SeenMessage(message.id, widget.groupModel.id, widget.groupModel.account.userID);
    wsChannel!.add(jsonEncode(WebSocketMessage(WebSocketService.messageTypeSeenMessage, stamp, ack)));
  }

  Future<void> _setUpWebSocket() async {
    GroupsService.instance.savedMessageReceiver = (GroupMessage message) {
      if (message.groupID != widget.groupModel.id) {
        // Not for us...
        return;
      }
      print("Adding message to chat id ${message.id}: ${message.content}");
      _addMessage(message);
      seenAck(message);
      // NOTE: GroupsService.notifyListeners() will be called after executing this savedMessageReceiver
      if (scrollController.positions.length == 1 && scrollController.position.pixels != 0) {
        scrollController.animateTo(0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.ease,
        );
      }
    };
    wsChannel = await WebSocketService.instance.getChannel(widget.groupModel.account);
    _wsSub = WebSocketSubscriber(widget.groupModel.account,
      [WebSocketService.messageTypeGroupMessage, WebSocketService.messageTypeGroupUpdate],
      (channel, message) {
        if (message == null) {
          if (wsChannel == channel) {
            return;
          }
          Toast.show(msg: channel != null ? "Connected" : "Disconnected",
              gravity: ToastGravity.BOTTOM);
        } else {
          if (message.type == WebSocketService.messageTypeGroupUpdate) {
            final update = GroupUpdate.fromJson(message.data);
            if (update.hasLeft(widget.groupModel.id)) {
              // Close the current chat
              Navigator.of(context).pop();
              Toast.show(msg: "This group is not available any more");
            } else if (update.hasNameChanged(widget.groupModel.id)) {
              // Group name has changed (not very nice - should be centralized?)
              widget.groupModel.name = update.name;
              setState(() {});
            }
          }
        }
        setState(() {
          wsChannel = channel;
        });
      }
    );
    WebSocketService.instance.subscribe(_wsSub!);
  }

  Future<List<GroupMessage>> _loadPreviousMessages() async {
    await GroupsService.instance.getGroups();
    for (final gm in widget.groupModel.messages) {
      _addMessage(gm);
    }
    await _setUpWebSocket();
    if (widget.groupModel.messages.isNotEmpty && widget.groupModel.lastReadID != widget.groupModel.messages.last.id) {
      // TODO: Scroll to lastReadID and update when scrolling?
      seenAck(widget.groupModel.messages.last);
      await GroupsService.instance.reSortGroups();
    }
    setState(() {});
    return widget.groupModel.messages;
  }

  @override
  void initState() {
    super.initState();
    if (widget.groupModel.isNew) {
      Future(() {
        widget.groupModel.clearNew();
      });
    }
    _futureMessages = _loadPreviousMessages();
    _userServiceFuture = UserService.forAccount(widget.groupModel.account);
    _userServiceFuture.whenComplete(() async {
      _userService = await _userServiceFuture;
      // Redraw to make sure we have latest user names
      setState(() {});
    });
    messageCtrl.text = widget.groupModel.draftMessage;
    // TODO: Currently we are receiving all messages for a chat once we join
    // // That could be too much, so maybe load 100 only and do the below
    // scrollController.addListener(() {
    //   if (scrollController.positions.length != 1 || !scrollController.position.atEdge || scrollController.offset == 0) {
    //     // Not at the top of the messages
    //     return;
    //   }
    //   widget.groupModel.loadPrevious();
    // });
  }

  @override
  void dispose() {
    if (_wsSub != null) {
      WebSocketService.instance.unsubscribe(_wsSub!);
    }
    GroupsService.instance.savedMessageReceiver = null;
    groupNameCtrl.dispose();
    messageCtrl.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void deleteButtonPressed() async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    finalAction(bool shouldDelete) async {
      Navigator.of(rootContext).pop();
      if (!shouldDelete) {
        return;
      }
      if (!await GroupsService.delete(widget.groupModel)) {
        Toast.show(msg: "Couldn't delete the group.");
        return;
      }
      Navigator.of(rootContext).pop();
      if (GroupsPage.navigatorKey.currentState!.canPop()) {
        GroupsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst);
      }
    }
    showDialog(
      context: rootContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Delete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text("Are you sure you want to permanently delete this group and all of its content?"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppConst.attentionColor)),
              onPressed: () => finalAction(true),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => finalAction(false),
            ),
          ],
        );
      },
    );
  }

  Widget _colorPickerLayoutBuilder(
      BuildContext context, List<Color> colors, PickerItem child) {
    return SizedBox(
      width: 300,
      height: 310,
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: [for (Color color in colors) child(color)],
      ),
    );
  }


  void showEditDialog(BuildContext context) {
    finalAction(bool shouldUpdate) async {
      final newText = groupNameCtrl.text.trim();
      if (!shouldUpdate) {
        Navigator.of(context).pop();
        return;
      }
      widget.groupModel.name = newText;
      final success = await GroupsService.save(widget.groupModel);
      if (!success) {
        Toast.show(msg: "Couldn't save group.. Duplicate name?");
        return;
      } else {
        Navigator.of(context).pop();
        setState(() {});
      }
    }

    groupNameCtrl.text = widget.groupModel.name;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return KeyboardVisibilityBuilder(
          builder: (context, isKeyboardVisible) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Edit Group'),
              content: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.groupModel.isAdmin)
                      RoundInputHint(ctrl: groupNameCtrl, hintText: "Group Name", autoFocus: false, disabled: !widget.groupModel.isAdmin,),
                    if (widget.groupModel.isAdmin)
                      AnimatedContainer(
                        height: isKeyboardVisible ? 0 : 10,
                        duration: const Duration(milliseconds: 300),
                        child: const SizedBox(height: 10)
                    ),
                    AnimatedContainer(
                      height: isKeyboardVisible ? 0 : 310,
                      duration: const Duration(milliseconds: 300),
                      child: BlockPicker(
                        useInShowDialog: true,
                        layoutBuilder: _colorPickerLayoutBuilder,
                        pickerColor: widget.groupModel.getColour,
                        onColorChanged: (Color colour) {
                          widget.groupModel.setColorFromColor(colour);
                        },
                      ),
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Delete', style: TextStyle(color: AppConst.attentionColor)),
                  onPressed: deleteButtonPressed,
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () => finalAction(true),
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => finalAction(false),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showPeopleDialog(BuildContext context) async {
    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()),);
    final usersService = await _userServiceFuture;
    Navigator.of(context, rootNavigator: true).pop();

    final members = <int, bool>{};
    for (final member in widget.groupModel.members) {
      if (member.id == widget.groupModel.account.userID) {
        continue;
      }
      members[member.id] = member.isAdmin;
    }
    final users = usersService.users;
    users.removeWhere((user) => user.id == widget.groupModel.account.userID);
    MultiUserWidget.show(
      users: users,
      members: members,
      callback: (newMembers) async {
        if (newMembers.isEmpty) {
          Toast.show(msg: "No users selected...");
          return;
        }
        // TODO: Add warning for removed users
        widget.groupModel.members.removeWhere((user) => user.id != widget.groupModel.account.userID);
        for (final member in newMembers.entries) {
          widget.groupModel.members.add(GroupUser(member.key, usersService.userMap[member.key]!.name, member.value, 0));
          print("Added ${member.key}");
        }
        final success = await GroupsService.save(widget.groupModel);
        if (!success) {
          Toast.show(msg: "Couldn't save group");
          return;
        } else {
          setState(() {});
        }
      },
      context: context,
      title: "Group Members",
      hint: "Tap on a User's name to add them to the group. Twice to make them an admin.",
      okButtonText: "Save"
    );
  }

  Future<void> startCall() async {
    final pathResponse = await widget.groupModel.getCallPath();
    if (pathResponse.status != 200) {
      print("Couldn't get call link: ${pathResponse.status} ${pathResponse.body}");
      Toast.show(msg: "Couldn't get call link: ${pathResponse.status} ${pathResponse.body}");
      return;
    } else {
      print("Got call link: ${pathResponse.body}");
    }
    final path = jsonDecode(pathResponse.body)["path"];
    MyApp.openVideoCallView(widget.groupModel.account.server + path);
  }

  Widget _groupHeader() {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 45,
                child: Center(child: Icon(Icons.arrow_back_ios_new_rounded, color: widget.groupModel.getColour, size: 25,)),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 9),
              alignment: Alignment.centerLeft,
              child: Container(
                  margin: const EdgeInsets.only(bottom: 5, left: 35),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupModel.title(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2,),
                      Text(
                        widget.groupModel.subtitle(),
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              child:  Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.groupModel.isAdmin)
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => showPeopleDialog(MyApp.navigatorKey.currentState!.context),
                          child: const Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Icon(Icons.people,
                                size: 30,
                                color: Colors.black
                            ),
                          ),
                        ),
                      if (widget.groupModel.isAdmin)
                        const SizedBox(width: 7,),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => showEditDialog(MyApp.navigatorKey.currentState!.context),
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(Icons.edit_outlined,
                              size: 30,
                              color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(width: 7,),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: startCall,
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(Icons.videocam_rounded,
                              size: 30,
                              color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]
      ),
    );
  }

  Widget _renderCluster(List<GroupMessage> cluster, int showDate, double mediaWidth) {
    final msgWidgets = <Widget>[];
    int cnt = 0;
    if (showDate > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          cluster.first.serverStamp);
      DateFormat df;
      if (showDate == 2) {
        df = DateFormat("d MMM yyyy・HH:mm");
      } else {
        df = DateFormat("HH:mm");
      }
      msgWidgets.add(Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
          child: Text(df.format(dt), style: kSecondaryFontStyle),
        ),
      ));
    }
    for (final msg in cluster) {
      bool popped = false;
      int index = cnt;
      final parentSetState = setState;
      msgWidgets.add(StatefulBuilder(
        builder: (context, setState) {
          var _tapPosition;
          return GestureDetector(
            onTapDown: (details) => _tapPosition = details.globalPosition,
            onLongPress: () => setState(() {
              popped = true;
              final overlay = Overlay.of(context).context.findRenderObject();
              if (overlay == null) {
                return;
              }
              showMenu(
                popUpAnimationStyle: AnimationStyle(curve: Curves.easeInOut, duration: const Duration(milliseconds: 150)),
                context: context,
                constraints: BoxConstraints(maxWidth: 85),
                shape: const RoundedRectangleBorder(borderRadius: kBordersAllReply),
                menuPadding: const EdgeInsets.all(0),
                position: RelativeRect.fromRect(
                    _tapPosition! & const Size(40, 40), // smaller rect, the touch area
                    Offset.zero & overlay.semanticBounds.size // Bigger rect, the entire screen
                ),
                items: kReactions).then((value) {
                if (value == 0) {
                  parentSetState(() {
                    replyTo = msg;
                    Toast.show(msg: "Replying to ${msg.userName}");
                  });
                } else if (value == 1) {
                  Clipboard.setData(ClipboardData(text: msg.content));
                  Toast.show(msg: "Copied to clipboard");
                } else if (value is String) {
                  // Reaction
                  _sendReaction(msg, value);
                }
                setState(() {
                  popped = false;
                });
              });
            }),
            child: _renderMessage(msg, popped, index == 0, index == cluster.length-1, mediaWidth),
          );
        },
      ));
      cnt++;
    }
    msgWidgets.add(SizedBox(height: 7)); // Some padding at the bottom
    return Column(children: msgWidgets);
  }

  String getUserName(String defaultName, int id) {
    if (_userService != null) {
      final user = _userService!.find(id);
      if (user != null) {
        return user.name;
      }
    }
    return defaultName;
  }

  String _getReplyToName(GroupMessage msg, GroupMessage replyToMsg, bool isOwn) {
    if (replyToMsg.userID == msg.userID) {
      return isOwn ? "⤷ to yourself" : "⤷ ${getUserName(msg.userName, msg.userID)} to themselves";
    }
    // We sent this message
    if (isOwn) {
      return "⤷ to ${getUserName(replyToMsg.userName, replyToMsg.userID)}";
    }
    // Someone else sent this message to us
    if (replyToMsg.userID == widget.groupModel.account.userID) {
      return "⤷ ${getUserName(msg.userName, msg.userID)} to you";
    }
    return "⤷ ${getUserName(msg.userName, msg.userID)} to ${getUserName(replyToMsg.userName, replyToMsg.userID)}";
  }

  void _sendReaction(GroupMessage msg, String reaction) {
    if (wsChannel == null) {
      return;
    }
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final message = GroupMessage(0, widget.groupModel.id, stamp, 0, 0, "", reaction, 0, msg.id);
    wsChannel!.add(jsonEncode(WebSocketMessage(WebSocketService.messageTypeGroupMessage, stamp, message)));
  }

  void _reactionsPopup(BuildContext context, GroupMessage msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Reactions'),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final reaction in msg.reactions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Text(reaction.reaction, style: const TextStyle(fontSize: kFontSize, color: Colors.black), strutStyle: StrutStyle(height: 1.2, forceStrutHeight: true)),
                        const SizedBox(width: 5),
                        Text(getUserName("", reaction.userID), style: kMainFontStyleGrey),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _renderMessage(GroupMessage msg, bool popped, bool first, bool last, double mediaWidth) {
    final isOwn = msg.userID == widget.groupModel.account.userID;
    final borderRadius = isOwn ? (
      first && last
        ? kBordersAll
        : first
            ? kBordersSharpBottomRight
            : last
                ? kBordersSharpTopRight
                : kBordersSharpRight
    ) : (
      first && last
        ? kBordersAll
        : first
          ? kBordersSharpBottomLeft
          : last
            ? kBordersSharpTopLeft
            : kBordersSharpLeft
    );
    double leftPad = 8, rightPad = 8;
    Color color, fontColor;
    MainAxisAlignment axisAlign;
    WrapAlignment wrapAlign;
    if (isOwn) {
      // Own message
      color = widget.groupModel.getColour.withOpacity(1);
      fontColor = Colors.white;
      axisAlign = MainAxisAlignment.end;
      wrapAlign = WrapAlignment.end;
    } else {
      // Someone else's message
      color = kOtherPersonMessageColor;
      fontColor = Colors.black;
      axisAlign = MainAxisAlignment.start;
      wrapAlign = WrapAlignment.start;
    }
    if (popped) {
      color = Colors.black;
      fontColor = Colors.white;
    }
    Widget? replyToWidget;
    if (msg.replyTo != 0) {
      final replyToMsg = widget.groupModel.findMessage(msg.replyTo);
      if (replyToMsg != null) {
        double maxWidth = mediaWidth*0.5;
        if (replyToMsg.content.length >= 35 && replyToMsg.content.length <= 60) {
          maxWidth = maxWidth * replyToMsg.content.length / 60;
        }
        replyToWidget = Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 2),
              child: Text(_getReplyToName(msg, replyToMsg, isOwn), style: kReplyToFontStyle),
            ),
            ClipRRect(
              borderRadius: kBordersAllReply,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.35)),
                child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    child: replyToMsg.getContent(context, kFontSize*3/4, Colors.black45)
                ),
              )
            ),
          ],
        );
      }
    }
    Widget contentWidget;
    // Do we need to render this message without padding and all that?
    if (msg.isSpecial) {
      contentWidget = GestureDetector(
          onDoubleTap: () => _sendReaction(msg, "❤️"),
          child: msg.getContent(context, kFontSize, fontColor)
      );
    } else {
      double maxWidth = mediaWidth*3/4;
      if (msg.content.length >= 35 && msg.content.length <= 60) {
        maxWidth = maxWidth * msg.content.length / 60;
      }
      contentWidget = ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(color: color),
            child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: GestureDetector(
                  onDoubleTap: () => _sendReaction(msg, "❤️"),
                  child: msg.getContent(context, kFontSize, fontColor)
                )
            ),
          )
      );
    }
    if (msg.reactions.isNotEmpty) {
      final reactions = <Widget>[];
      for (final reaction in msg.reactions) {
        reactions.add(Text(reaction.reaction, style: TextStyle(fontSize: kFontSize*0.9, color: Colors.black), strutStyle: StrutStyle(height: 1.2, forceStrutHeight: true)));
      }
      contentWidget = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Container(child: contentWidget),
          ),
          Positioned(
            bottom: 0,
            right: 5,
            child: GestureDetector(
              onTap: () => _reactionsPopup(context, msg),
              child: ClipRRect(
                borderRadius: kBordersAllReply,
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: ClipRRect(
                      borderRadius: kBordersAllReply,
                      child: Container(
                        color: kOtherPersonMessageColor,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5, right: 4, bottom: 2, top: 3),
                          child: Row(
                            mainAxisAlignment: axisAlign,
                            children: reactions,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      );
    }
    List<Widget> seenBy = [];
    for (var member in widget.groupModel.members) {
      if (msg.userID != member.id
          && member.id != widget.groupModel.account.userID
          && member.lastSeenMessageId == msg.id) {

        seenBy.add(Padding(
          padding: const EdgeInsets.only(left: 4, top: 7),
          child: Text('✓ ${member.name}', style: kSecondaryFontStyle),
        ));
      }
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPad, first ? 8 : 2, rightPad, 2),
      child: Column(
        children: [
          if (first && !isOwn && msg.replyTo == 0)
          Row(
            mainAxisAlignment: axisAlign,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 3),
                child: Text(getUserName(msg.userName, msg.userID) , style: kSecondaryFontStyle),
              ),
            ]
          ),
          if (replyToWidget != null)
            Row(
              mainAxisAlignment: axisAlign,
              children: [replyToWidget],
            ),
          Row(
            mainAxisAlignment: axisAlign,
            children: [contentWidget],
          ),
          if (seenBy.isNotEmpty)
            Row(
              mainAxisAlignment: axisAlign,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width*3/4,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Wrap(
                      alignment: wrapAlign,
                      children: seenBy,
                    ),
                  ),
                 )
              ],
            ),
        ],
      ),
    );
  }

  void showGiphy(bool stickers) {
    GiphyWidget(stickers: stickers, query: "", onSelected: (url) => setState(() {
        if (wsChannel == null) {
          return;
        }
        final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
        final message = GroupMessage(0, widget.groupModel.id, stamp, 0, 0, "", "[image:$url]", replyTo?.id ?? 0, 0);
        wsChannel!.add(jsonEncode(WebSocketMessage(WebSocketService.messageTypeGroupMessage, stamp, message)));
      })).show(context);
  }

  void sendMessage() {
    String content = messageCtrl.text;
    if (content.isEmpty) {
      // Send thumbs-up
      content = "👍";
    } else {
      content = content.trim();
      if (content == "") {
        return;
      }
    }
    lastEnteredValue = "";
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final message = GroupMessage(0, widget.groupModel.id, stamp, 0, 0, "", content, replyTo?.id ?? 0, 0);
    wsChannel!.add(jsonEncode(WebSocketMessage(WebSocketService.messageTypeGroupMessage, stamp, message)));
    messageCtrl.text = "";
    widget.groupModel.saveDraftMessage("");

    if (replyTo != null) {
      setState(() {
        replyTo = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Widget mainWidget = FutureBuilder<List<GroupMessage>>(
      future: _futureMessages,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (messageClusters.isEmpty) {
          return const EmptyInfoWidget(Icons.message, "Start a new chat here");
        }
        final mediaWidth = MediaQuery.of(context).size.width;
        return ListView.builder(
          controller: scrollController,
          reverse: true,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          padding: const EdgeInsets.all(5),
          itemCount: messageClusters.length,
          itemBuilder: (context, index) {
            int showDate = 0;
            if (messageClusters.length-1-index-1 >= 0) {
              final diff = messageClusters[messageClusters.length-1-index].first.serverStamp -
                  messageClusters[messageClusters.length-1-index-1].first.serverStamp;
              if (diff > 60*60000) {
                showDate = 2;
              } else if (diff > 3*60000) {
                showDate = 1;
              }
            } else {
              showDate = 2;
            }
            return _renderCluster(messageClusters[messageClusters.length-1-index], showDate, mediaWidth);
          },
        );
      }
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _groupHeader(),
          const SizedBox(height: 1,),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    onVerticalDragEnd: (details) {
                      if (details.velocity.pixelsPerSecond.dy>0) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                    },
                    child: mainWidget,
                  ),
                ),
                if (replyTo != null)
                  Container(
                    height: 52,
                    width: double.infinity,
                    color: Colors.grey.withOpacity(0.2),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 17, 5, 12),
                          child: Text.rich(TextSpan(
                            children: [
                              TextSpan(text: "Replying to ", style: kSecondaryFontStyle),
                              TextSpan(text: getUserName(replyTo!.userName, replyTo!.userID), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              TextSpan(text: ": ${replyTo!.shortPreview}", style: kSecondaryFontStyle),
                            ]
                          )),
                        ),
                        Positioned(
                          top: 3,
                          right: 3,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                replyTo = null;
                                // Scroll to the bottom
                                if (scrollController.positions.length == 1 && scrollController.position.pixels != 0) {
                                  scrollController.animateTo(0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.ease,
                                  );
                                }
                              });
                            },
                            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 30),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      width: 35,
                      child: IconButton(
                          disabledColor: Colors.grey,
                          onPressed: wsChannel==null ? null : ()=>showGiphy(false),
                          icon: Icon(Icons.gif_box_outlined, color: wsChannel==null ? Colors.grey : AppConst.iconColor, size: 30)
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: 45,
                      child: IconButton(
                          disabledColor: Colors.grey,
                          onPressed: wsChannel==null ? null : ()=>showGiphy(true),
                          icon: Icon(Icons.emoji_emotions_outlined, color: wsChannel==null ? Colors.grey : AppConst.iconColor, size: 30)
                      ),
                    ),
                    Expanded(
                      child: MessageInput(ctrl: messageCtrl, fontSize: kFontSize, hintText: wsChannel==null ? "Reconnecting..." : null, disabled: wsChannel==null, onChanged: (value) {
                        if (value==null) {
                          return;
                        }
                        widget.groupModel.saveDraftMessage(value!);
                        if (value!.isEmpty ^ lastEnteredValue.isEmpty) {
                          // Change send button icon
                          setState(() {});
                        }
                        lastEnteredValue = value!;
                      },)
                    ),
                    Container(
                      alignment: Alignment.bottomCenter,
                      width: 50,
                      child: IconButton(
                        disabledColor: Colors.grey,
                        onPressed: wsChannel==null ? null : sendMessage,
                        icon: Icon(messageCtrl.text.isNotEmpty
                            ? Icons.send_rounded
                            : Icons.thumb_up_rounded,
                          color: wsChannel==null ? Colors.grey : AppConst.iconColor, size: 30,
                        )
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}


