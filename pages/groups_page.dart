import 'package:flutter/material.dart';
import '../models/group_model.dart';
import 'groups_list_page.dart';
import 'group_feed_page.dart';

class GroupsPage extends StatefulWidget {
  static int index = -1;

  GroupsPage(int idx, {Key? key}) : super(key: key) {
    index = idx;
  }
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> with AutomaticKeepAliveClientMixin<GroupsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Navigator(
        key: GroupsPage.navigatorKey,
        initialRoute: "/",
        observers: [
          HeroController(),
        ],
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case GroupFeedPage.route:
              builder = (_) => GroupFeedPage(groupModel: settings.arguments as GroupModel);
              break;
            default:
              builder = (_) => const GroupsListPage();
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      )
    );
  }
}


