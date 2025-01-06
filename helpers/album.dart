import 'dart:convert';

import 'package:app/helpers/group.dart';
import 'package:app/models/album_base_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/external_album_model.dart';
import 'package:app/models/moment_model.dart';
import 'package:app/pages/album_thumbs_page.dart';
import 'package:app/pages/moment_thumbs_page.dart';
import 'package:app/services/groups_service.dart';
import 'package:app/widget/cached_thumb_widget.dart';
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

class Album {
  static const expireIn1day = 24*86400;
  static const expireIn7days = 7*24*86400;
  static const expireIn30days = 30*24*86400;
  static const expireIn1year = 365*24*86400;
  static const expireNever = 0;
  static const Map<int, String> expireMap = {
    expireIn1day: "1 day",
    expireIn7days: "7 days",
    expireIn30days: "1 month",
    expireIn1year: "1 year",
    expireNever: "Never expires",
  };

  static Future<bool> shareAssets(List<AssetModel> assets) async {
    final album = await AlbumsService.instance.createAlbum(assets.first.account, "Shared", hidden: true);
    if (album == null) {
      Toast.show(msg: "Could not create shared data");
      return false;
    }
    final response = await AssetModel.addToAlbum(assets.first.account, album.id, assets.map((a) => a.id).toList(growable: false));
    if (response.status != 200) {
      print("Couldn't add assets to hidden album ${album.id}");
      Toast.show(msg: "Could not share assets");
      return false;
    }
    await share(album);
    return true;
  }

  static void _shareMenu(AlbumModel albumInfo, dynamic info) async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    showModalBottomSheet(
      context: rootContext,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Share in...'),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('Chat Group'),
                      onPressed: () async {
                        Navigator.pop(context);
                        Group.share(albumInfo.account.server+info["path"]);
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('Another Application'),
                      onPressed: () {
                        Navigator.pop(context);
                        Share.share((albumInfo.hidden?"":info["title"] + ":\n") + albumInfo.account.server+info["path"],
                          subject: info["title"],
                          sharePositionOrigin: const Rect.fromLTWH(50, 150, 10, 10), // TODO: Better coordinates
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> share(AlbumModel albumInfo) async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    int expires = expireNever;
    int showOriginal = 1;
    final willShare = await showDialog<int>(
      context: rootContext,
      builder: (context) => AlertDialog(
        title: Text(albumInfo.hidden ? "Share" : "Share '"+albumInfo.name+"'"),
        content: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How long do you want to make this valid for?'),
              const SizedBox(height: 15,),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isDense: false,
                  value: expires,
                  onChanged: (newValue) => setState(() {
                    expires = newValue ?? 0;
                  }),
                  items: expireMap.entries.map((e) => DropdownMenuItem<int>(child: Text(e.value), value: e.key,)).toList(growable: false),
                ),
              ),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Enable original download (including location, etc)"),
                  value: showOriginal==1,
                  onChanged: (newVal) => setState(() {
                    showOriginal = (newVal??false) ? 1 : 0;
                  })
              ),
            ],
          );
        },),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(-1),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(expires),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (willShare==null || willShare==-1) {
      return;
    }
    final response = await albumInfo.getShareInfo(willShare, 1-showOriginal);
    final info = jsonDecode(response.body);
    if (response.status != 200) {
      Toast.show(msg: info["error"]);
      return;
    }
    _shareMenu(albumInfo, info);
  }

  static void addToDialog(ListableService albumsService, Set<int> selected, List<AssetModel> assets, Function(bool, int) callback) async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    finalAction(int albumId) async {
      Navigator.of(rootContext).pop();
      if (albumId <= 0) {
        return;
      }
      MultiResultResponse response;
      if (selected.isEmpty) {
        // Add all assets
        response = await AssetModel.addToAlbum(assets.first.account, albumId, assets.map((a) => a.id).toList(growable: false));
      } else {
        // Add only selected assets
        response = await AssetModel.addToAlbum(assets.first.account, albumId, selected.map((i) => assets[i].id).toList(growable: false));
      }
      if (response.status != 200) {
        Toast.show(msg: "Some assets could not be added to the album");
      } else {
        Toast.show(msg: "All assets have been added to the album");
      }
      callback(response.status == 200, albumId);
      // Update list so we can have updated Hero thumb
      // TODO: We should be able to have the thumb in a better way
      await AlbumsService.reloadAccount(assets[0].account);
      AlbumsService.instance.notifyListeners();
    }
    SelectOrAddAlbumWidget.show(albumsService, finalAction, rootContext, "Add to Album", "Select Album");
  }

  static Widget getPreview(BuildContext context, AlbumBaseModel album) {
    double fontSize = album is AlbumModel ? 20 : 17;
    double fontSizeSub = album is AlbumModel ? 14 : 13;
    Widget subtitle = Text(
      album.subtitle,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSizeSub,
      ),
    );
    if (!album.isOwn && album is AlbumModel) {
      subtitle = Row(
        children: [
          subtitle,
          const SizedBox(width: 3,),
          const Icon(Icons.people, color: Colors.white,size: 18,),
        ],
      );
    }
    return GestureDetector(
      onTap: () => album is ExternalAlbumModel
          ? Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => Scaffold(
                    appBar: AppBar(
                      backgroundColor: Colors.black,
                      toolbarHeight: 0,
                    ),
                    body: AlbumThumbsPage(albumInfo: album)
                )
            ))
          : (album is AlbumModel
            ? Navigator.of(context).pushNamed(AlbumThumbsPage.route, arguments: album)
            : Navigator.of(context).pushNamed(MomentThumbsPage.route, arguments: album)
            ),
      child: Hero(
        tag: album.tag,
        transitionOnUserGestures: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CachedThumb(asset: album.heroImage, fit: true, size: CachedThumb.big),
                ),
                Container(
                  alignment: Alignment.bottomLeft,
                  decoration:  BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(00),
                        Colors.black.withAlpha(230),
                      ],
                      stops: const [0.5, 1],
                    ),
                  ),
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 5, left: 10),
                      child: Stack(
                        children: [Positioned(
                          left: 7,
                          bottom: 7,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle,
                            ],
                          ),
                        )],
                      )
                    //Text(albumsToRender[index].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
                  ),
                ),
              ]
          ),
        ),
      ),
    );
  }
}
