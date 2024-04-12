import 'package:app/pages/bucket_list_page.dart';
import 'package:app/pages/settings_main_page.dart';
import 'package:app/pages/user_list_page.dart';
import 'package:app/services/bucket_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';


class SettingsPage extends StatefulWidget {
  static late int index = -1;
  SettingsPage(int idx, {Key? key}) : super(key: key) {
    index = idx;
  }
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin<SettingsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Navigator(
        key: SettingsPage.navigatorKey,
        initialRoute: "/",
        observers: [
          HeroController(),
        ],
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case BucketListPage.route:
              builder = (_) => BucketListPage(settings.arguments as AccountModel);
              break;
            case UserListPage.route:
              builder = (_) => UserListPage(settings.arguments as AccountModel);
              break;
            default:
              builder = (_) => const SettingsMainPage();
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      )
    );
  }
}


