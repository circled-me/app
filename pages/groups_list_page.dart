import 'dart:convert';
import 'dart:collection';

import 'package:app/app_consts.dart';
import 'package:app/helpers/user.dart';
import 'package:app/main.dart';
import 'package:app/models/group_user_model.dart';
import 'package:app/pages/group_feed_page.dart';
import 'package:app/services/user_service.dart';
import 'package:app/widget/empty_info_widget.dart';
import 'package:app/widget/multi_user_widget.dart';
import 'package:app/helpers/toast.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app/widget/webview_dialog_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../models/account_model.dart';
import '../models/group_model.dart';
import '../services/groups_service.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';


class GroupsListPage extends StatefulWidget {
  static final scrollController = ScrollController();

  const GroupsListPage({Key? key}) : super(key: key);

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  late List<GroupModel> groups = [];
  TextEditingController groupNameCtrl = TextEditingController();

  @override
  void dispose() {
    groupNameCtrl.dispose();
    super.dispose();
  }

  Future<AccountModel?> selectAccount(BuildContext context) async {
    AccountModel account;
    if (AccountsService.getAccounts.isEmpty) {
      Toast.show(msg: "You need to add an account first");
      return null;
    } else if (AccountsService.getAccounts.length == 1) {
      account = AccountsService.getAccounts.first;
    } else {
      final selected = await User.switchAccount(AccountsService.getAccounts.first);
      if (selected == null) {
        Toast.show(msg: "You need to select an account");
        return null;
      }
      account = selected!;
    }
    return account;
  }

  void openVideoCallView(String url) {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) => request.grant(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print("WebView is loading (progress : $progress%)");
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onHttpError: (HttpResponseError error) {
            print('HTTP error: $error');
          },
          onWebResourceError: (WebResourceError error) {
            print('Web Resource error: $error');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation Request: $request');
            return NavigationDecision.navigate;
          },
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      // AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    controller.clearCache();
    // Finally, load the URL
    controller.loadRequest(Uri.parse(url));

    showDialog(
      context: rootContext,
      barrierDismissible: true,

      builder: (BuildContext context) {
        return WebViewDialog(controller: controller);
      },
    );
  }

  Future<String> resetCallUrl(AccountModel account) async {
    String url = '';
    // Show a dialog to confirm the reset
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Reset Call Link"),
        content: const Text("Are you sure you want to reset the call link?\nThis will invalidate the previous link."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppConst.attentionColor),
            onPressed: () async {
              url = await getCallUrl(account, true);
              Navigator.of(context).pop(true);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
    return url;
  }

  Future<String> getCallUrl(AccountModel account, bool reset) async {
    final pathResponse = await account.getCallPath(reset);
    if (pathResponse.status != 200) {
      print("Couldn't get call link: ${pathResponse.status} ${pathResponse.body}");
      Toast.show(msg: "Couldn't get call link: ${pathResponse.status} ${pathResponse.body}");
      return '';
    }
    final path = jsonDecode(pathResponse.body)["path"];
    return account.server + path;
  }

  Future<void> createNewCall(BuildContext context) async {
    final account = await selectAccount(context);
    if (account == null) {
      return;
    }
    String callUrl = await getCallUrl(account, false);
    if (callUrl.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Video Call"),
        content: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Share the call link with the other participant(s).\n\nYou will receive a call once someone joins or you can join the call straight away.\n\nYour personal call link is:"),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: callUrl));
                  Toast.show(msg: "Link copied to clipboard", gravity: Toast.ToastGravityCenter);
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Text(callUrl, style: const TextStyle(color: Colors.blue),),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => Share.share(callUrl,
                      sharePositionOrigin: const Rect.fromLTWH(50, 150, 10, 10), // TODO: Better coordinates
                    ),
                    icon: const Icon(Icons.share)
                  ),
                  IconButton(
                    onPressed: () async {
                      final newUrl = await resetCallUrl(account);
                      print("New call link: $newUrl");
                      if (newUrl.isNotEmpty) {
                        // Copy the new link to the clipboard
                        await Clipboard.setData(ClipboardData(text: newUrl));
                        Toast.show(msg: "Link reset and copied to clipboard", gravity: Toast.ToastGravityCenter);
                        setState(() {
                          callUrl = newUrl;
                        });
                      }
                    }, // Just to trigger a rebuild
                    icon: const Icon(Icons.recycling)
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    MyApp.openVideoCallView(callUrl);
                  },
                  child: const Text("Join Call"),
                ),
              ),
            ]
          );
        }
      ),
    ),
    );
  }

  Future<void> createNewGroup(BuildContext context) async {
    final account = await selectAccount(context);
    if (account == null) {
      return;
    }
    // Fetch all users
    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()),);
    final usersService = await UserService.forAccount(account);
    Navigator.of(context, rootNavigator: true).pop();

    final members = <int, bool>{};
    final users = usersService.users;
    users.removeWhere((user) => user.id == account.userID);
    MultiUserWidget.show(
      users: users,
      members: members,
      callback: (newMembers) async {
        if (newMembers.isEmpty) {
          Toast.show(msg: "No users selected...");
          return;
        }
        List<GroupUser> members = [GroupUser(account.userID, usersService.userMap[account.userID]!.name, true, 0)];
        for (final member in newMembers.entries) {
          members.add(GroupUser(member.key, usersService.userMap[member.key]!.name, member.value, 0));
        }
        final newGroup = await GroupsService.instance.createGroup(account, members);
        if (newGroup == null) {
          Toast.show(msg: "Couldn't save group");
          return;
        } else {
          setState(() {});
          Navigator.of(context).pushNamed(GroupFeedPage.route, arguments: newGroup);
        }
      },
      context: context,
      title: "Create Room",
      hint: "Tap on a User's name to add them to the room. Twice to make them an admin.",
      okButtonText: "Create"
    );
  }

  Future<void> _updateGroupFavourite(GroupModel group) async {
    group.favourite = !group.favourite;
    await group.saveRemote();
    GroupsService.instance.reSortGroups();
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    final groupsService = Provider.of<GroupsService>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<GroupModel>>(
        future: groupsService.getGroups(),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final groupsToRender = snapshot.data!;
          if (groupsToRender.isEmpty) {
            return const Center(child: EmptyInfoWidget(Icons.group, "You haven't been invited\nto any rooms yet..."));
          }
          return GridView.builder(
            controller: GroupsListPage.scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              crossAxisCount: 1,
              childAspectRatio: 5,
            ),
            itemCount: groupsToRender.length,
            itemBuilder: (context, index) {
              final unread = groupsToRender[index].hasUnread;
                final fontWeight = unread ? FontWeight.bold : FontWeight.normal;
                Widget rightWidget;
                if (unread) {
                  rightWidget = const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.message, color: Colors.black)
                  );
                } else {
                  rightWidget = IconButton(
                    color: Colors.black,
                    onPressed: () => _updateGroupFavourite(groupsToRender[index]),
                    icon: Icon(
                        groupsToRender[index].favourite ? Icons.star : Icons
                            .star_outline),
                  );
                }
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(GroupFeedPage.route, arguments: groupsToRender[index]),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 15, 7, 0),
                    color: Colors.white,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 7,
                            alignment: Alignment.centerLeft,
                            color: groupsToRender[index].getColour,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 9),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 5, left: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupsToRender[index].title(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: fontWeight,
                                    ),
                                  ),
                                  const SizedBox(height: 2,),
                                  Text(
                                    groupsToRender[index].messagePreview(),
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: fontWeight,
                                    ),
                                  ),
                                ],
                              )
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.only(right: 45),
                            child: Text(
                              groupsToRender[index].messageTime(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: fontWeight,
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child:  rightWidget,
                          ),
                        ]
                      ),
                    ),
                  ),
                );
            }
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: !AccountsService.getAccounts.first.canCreateGroups() ? null : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.white,
            foregroundColor: AppConst.mainColor,
            heroTag: null,
            onPressed: () => createNewGroup(context),
            child: const Icon(Icons.add, size: 30,),
          ),
          const SizedBox(width: 15),
          FloatingActionButton(
            backgroundColor: Colors.white,
            foregroundColor: AppConst.mainColor,
            heroTag: null,
            onPressed: () => createNewCall(context),
            child: const Icon(Icons.videocam_rounded, size: 30,),
          ),
        ],
      ),
    );
  }
}


