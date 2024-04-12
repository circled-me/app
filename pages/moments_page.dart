import 'package:app/models/album_model.dart';
import 'package:app/pages/album_list_page.dart';
import 'package:app/pages/album_thumbs_page.dart';
import 'package:app/pages/moment_list_page.dart';
import 'package:app/pages/moment_thumbs_page.dart';

import 'package:flutter/material.dart';

import '../models/moment_model.dart';


class MomentsPage extends StatefulWidget {
  static late int index = -1;
  MomentsPage(int idx, {Key? key}) : super(key: key) {
    index = idx;
  }
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> with AutomaticKeepAliveClientMixin<MomentsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Navigator(
        key: MomentsPage.navigatorKey,
        initialRoute: "/",
        observers: [
          HeroController(),
        ],
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case MomentThumbsPage.route:
              builder = (_) => MomentThumbsPage(momentInfo: settings.arguments as MomentModel);
              break;
            default:
              builder = (_) => const MomentListPage();
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      )
    );
  }
}


