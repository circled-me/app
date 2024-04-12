import 'package:app/models/album_model.dart';
import 'package:app/pages/album_list_page.dart';
import 'package:app/pages/album_thumbs_page.dart';

import 'package:flutter/material.dart';


class AlbumsPage extends StatefulWidget {
  static late int index = -1;
  AlbumsPage(int idx, {Key? key}) : super(key: key) {
    index = idx;
  }
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> with AutomaticKeepAliveClientMixin<AlbumsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Navigator(
        key: AlbumsPage.navigatorKey,
        initialRoute: "/",
        observers: [
          HeroController(),
        ],
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case AlbumThumbsPage.route:
              builder = (_) => AlbumThumbsPage(albumInfo: settings.arguments as AlbumModel);
              break;
            default:
              builder = (_) => const AlbumListPage();
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      )
    );
  }
}


