import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app/app_consts.dart';
import 'package:app/helpers/toast.dart';
import 'package:app/helpers/user.dart';
import 'package:app/main.dart';
import 'package:app/pages/albums_page.dart';
import 'package:app/pages/groups_list_page.dart';
import 'package:app/pages/moments_page.dart';
import 'package:app/pages/settings_page.dart';
import 'package:app/services/groups_service.dart';
import 'package:app/services/uni_link_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import '../services/accounts_service.dart';
import 'package:flutter/material.dart';

import 'album_list_page.dart';
import 'groups_page.dart';
import 'moment_list_page.dart';
import 'settings_main_page.dart';
import 'login_page.dart';
import 'thumbs_page.dart';

class TabsPage extends StatefulWidget {
  const TabsPage({Key? key}) : super(key: key);

  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late Future<bool> _checkAccountsFuture;
  final _pageViewController = PageController();
  int _gotoGroup = 0;
  String _gotoToken = '';

  String _generateSecureRandomString(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  void onNewInvite(String server, String token) {
    if (server.isEmpty || token.isEmpty) {
      return;
    }
    // Show YES/NO dialog to confirm if user wants to choose password
    showDialog<bool>(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("You have been invited!"),
      content: Text("Welcome to the '$server' server.\n\nDo you want to create username/password?\n\nIf you choose NO, a random username/password will be created for you."),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (context) => LoginPage(closable: true, server: server, token: token)));
          },
          child: const Text('Yes'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Create random password
            final userName = "user$token";
            final randomPassword = _generateSecureRandomString(32);
            // Login with the new credentials
            User.login(server, token, userName, randomPassword, true).then((error) {
              if (error.isNotEmpty) {
                Toast.show(msg: error);
                return;
              }
              Toast.show(msg: "Successfully logged into your new account");
            });
          },
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppConst.attentionColor),),
        ),
      ],
    ));
  }

  Future<bool> _checkAccounts(BuildContext context) async {
    await AccountsService.loadAccounts();
    if (AccountsService.getAccounts.isEmpty) {
      _selectedIndex = 0;
    }
    final uniLinkProcessed = UniLinksService.subscribe((Uri uri) {
      print("Tabs called with uri: "+uri.toString());
      // Handle invitation URIs: /invite/<server>/<token>
      if (uri.pathSegments.length == 3 && uri.pathSegments[0] == "invite") {
        onNewInvite(uri.pathSegments[1], uri.pathSegments[2]);
        return true;
      }
      // Handle chat URIs: /group/<token>/<id>
      if (uri.pathSegments.length > 2 && uri.pathSegments[0] == "group") {
        setState(() {
          _gotoGroup = int.parse(uri.pathSegments[2]);
          _gotoToken = uri.pathSegments[1];
        });
        return true;
      }
      return false;
    });
    if (!uniLinkProcessed && AccountsService.getAccounts.isEmpty) {
      Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (context) => const LoginPage()));
      return false;
    }
    return true;
  }

  // Returns false if there's no way to pop more (i.e. we are on a top-level screen at initial state)
  bool _onItemTapped(int index) {
    if (index != _selectedIndex) {
      _selectedIndex = index;
      _pageViewController.jumpToPage(index);
      return false;
    }
    bool result = false;
    if (index == ThumbsPage.index) {
      if (ThumbsPage.scrollController.position.pixels != 0) {
        result = true;
        // Go to the top of thumbs if tapped again
        ThumbsPage.scrollController.animateTo(0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    }
    if (index == AlbumsPage.index) {
      // Go to the top if tapped again
      if (AlbumsPage.navigatorKey.currentState!.canPop()) {
        result = true;
        AlbumsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst);
      } else if (AlbumListPage.scrollController.position.pixels != 0) {
        result = true;
        // Go to the first Album if tapped even once again
        AlbumListPage.scrollController.animateTo(0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    }
    if (index == MomentsPage.index) {
      // Go to the top if tapped again
      if (MomentsPage.navigatorKey.currentState!.canPop()) {
        result = true;
        MomentsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst);
      } else if (MomentListPage.scrollController.position.pixels != 0) {
        result = true;
        // Go to the first Album if tapped even once again
        MomentListPage.scrollController.animateTo(0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    }
    if (index == GroupsPage.index) {
      // Go to the top if tapped again
      if (GroupsPage.navigatorKey.currentState!.canPop()) {
         result = true;
        GroupsPage.navigatorKey.currentState!.pop();
        // GroupsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst);
      } else {
        // Go to the first Group if tapped even once again
        GroupsListPage.scrollController.animateTo(0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    }
    if (index == SettingsPage.index) {
      // Go to the top if tapped again
      if (SettingsPage.navigatorKey.currentState!.canPop()) {
        result = true;
        SettingsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst);
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _checkAccountsFuture = _checkAccounts(context);
  }

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  List<Widget> _getPages(AccountsService accounts) {
    final pages = <Widget>[];
    int tabCount = 0;
    final hasBackup = accounts.hasAnyPhotoUpload();
    if (hasBackup) {
      pages.add(ThumbsPage(tabCount++));
    }
    // Always add Albums
    pages.add(AlbumsPage(tabCount++));
    if (hasBackup) {
      pages.add(MomentsPage(tabCount++));
    }
    if (!accounts.isEmpty) {
      pages.add(GroupsPage(tabCount++));
    }
    // Always add Settings
    pages.add(SettingsPage(tabCount++));
    if (_selectedIndex > tabCount) {
      _selectedIndex = tabCount;
    }
    return pages;
  }

  List<BottomNavigationBarItem> _getTabs(AccountsService accounts, GroupsService groupsService) {
    final tabs = <BottomNavigationBarItem>[];
    final hasBackup = accounts.hasAnyPhotoUpload();
    if (hasBackup) {
      tabs.add(const BottomNavigationBarItem(
        icon: Icon(Icons.photo),
        label: "Library",
      ));
    }
    tabs.add(const BottomNavigationBarItem(
      icon: Icon(Icons.photo_library),
      label: "Albums",
    ));
    if (hasBackup) {
      tabs.add(const BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: "Moments",
      ));
    }
    Widget groupsIcon = const Icon(Icons.group);
    final numUnreadGroups = groupsService.numUnreadGroups();
    if (numUnreadGroups > 0) {
      FlutterAppBadger.updateBadgeCount(numUnreadGroups);
      groupsIcon = Badge(
        label: Text(numUnreadGroups.toString()),
        backgroundColor: Colors.deepOrange,
        child: groupsIcon,
      );
    } else {
      FlutterAppBadger.removeBadge();
    }
    if (numUnreadGroups != MyApp.numUnread) {
      MyApp.numUnread = numUnreadGroups;
      for (var account in AccountsService.getAccounts) {
        account.updatePushServer();
      }
    }
    if (!accounts.isEmpty) {
      tabs.add(BottomNavigationBarItem(
        icon: groupsIcon,
        label: 'Connect',
      ));
    }
    tabs.add(const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: "Settings",
    ));
    if (_selectedIndex > tabs.length) {
      _selectedIndex = tabs.length-1;
    }
    return tabs;
  }

  Future<bool> _backButtonPressed() async {
    if (_onItemTapped(_selectedIndex)) {
      // If we can pop, then no need to exit
      return false;
    }
    final rootContext = MyApp.navigatorKey.currentState!.context;
    return await showDialog<bool>(
      context: rootContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('circled.me'),
        content: const Text('Do you want to exit an application?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('YES', style: TextStyle(color: AppConst.attentionColor),),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accountsService = Provider.of<AccountsService>(context);
    final groupsService = Provider.of<GroupsService>(context);
    return WillPopScope(
      onWillPop: _backButtonPressed,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          toolbarHeight: 0,
        ),
        body: FutureBuilder<bool>(
          future: _checkAccountsFuture,
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Logging in. Please wait..."),
                  ],
                ),
              );
            }
            if (_gotoGroup > 0 && _gotoToken.isNotEmpty) {
              Timer(Duration(milliseconds: 200), () => setState(() {
                _pageViewController.jumpToPage(GroupsPage.index);
                GroupsService.instance.goto(_gotoGroup, _gotoToken);
                _gotoGroup = 0;
                _gotoToken = '';
              }));
            }
            return PageView(
              controller: _pageViewController,
              allowImplicitScrolling: false,
              physics: const NeverScrollableScrollPhysics(),
              children: _getPages(accountsService),
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: _getTabs(accountsService, groupsService),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          unselectedFontSize: 13,
          selectedFontSize: 14,
        ),
      ),
    );
  }
}

