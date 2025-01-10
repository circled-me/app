import 'dart:convert';
import 'dart:collection';

import 'package:app/app_consts.dart';
import 'package:app/helpers/album.dart';
import 'package:app/helpers/asset.dart';
import 'package:app/helpers/asset_actions.dart';
import 'package:app/models/album_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/helpers/toast.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/moment_model.dart';
import '../services/listable_service.dart';
import '../services/moments_service.dart';
import '../widget/cached_thumb_widget.dart';
import '../widget/select_add_album_widget.dart';
import '../widget/simple_gallery_widget.dart';
import '../widget/simple_photo_viewer.dart';
import '../widget/simple_video_player_widget.dart';

import '../models/asset_model.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';



class MomentThumbsPage extends StatefulWidget {
  static const route = "/moment";
  final MomentModel momentInfo;
  const MomentThumbsPage({Key? key, required this.momentInfo}) : super(key: key);

  @override
  State<MomentThumbsPage> createState() => _MomentThumbsPageState();
}

class _MomentThumbsPageState extends State<MomentThumbsPage> {
  final Set<int> selected = SplayTreeSet(); // Sorted set
  final List<AssetBaseModel> assets = [];
  final _scrollController = ScrollController();

  static const double _baseHeaderHeight = 200;
  static const double _minHeaderHeight = 120;
  double _headerHeight = _baseHeaderHeight;

  @override
  void dispose() {
    _scrollController.removeListener(_userScrolled);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_userScrolled);
  }

  void _userScrolled() {
    double newHeaderHeight;
    if (_scrollController.offset/2 < _baseHeaderHeight - _minHeaderHeight) {
      newHeaderHeight = _baseHeaderHeight - _scrollController.offset/2;
    } else {
      newHeaderHeight = _minHeaderHeight;
    }
    if (_headerHeight != newHeaderHeight) {
      setState(() {_headerHeight = newHeaderHeight;});
    }
  }

  Future<List<AssetBaseModel>> _getAssets() async {
    if (assets.isNotEmpty) {
      return assets;
    }
    final result = await widget.momentInfo.getAssets();
    for (final a in result) {
      assets.add(a);
    }
    return assets;
  }

  void selectThumb(int index) => setState(() {
    if (selected.contains(index)) {
      selected.remove(index);
    } else {
      selected.add(index);
    }
  });

  void addButtonPressed(ListableService albumsService, bool share) {
    Album.addToDialog(albumsService, selected, assets.whereType<AssetModel>().toList(), (success, albumId) {
      if (success && share) {
        final album = AlbumsService.getAlbum(albumId);
        if (album != null) {
          Album.share(album);
        }
      }
      setState(() => () {});
    });
  }

  void shareButtonPressed() async {
    if (await Album.shareAssets(selected.map((i) => assets[i] as AssetModel).toList())) {
      setState(() {
        selected.clear();
      });
    }
  }

  void downloadButtonPressed() async {
    Asset.downloadDialog(selected, assets, (result) {
      Toast.show(msg: result ? "All downloaded!" : "Couldn't downloaded some of the assets...");
      selected.clear();
      setState(() => () {});
    });
  }

  Widget _albumHeader(double height, ListableService albumsService) {
    return Hero(
      tag: widget.momentInfo.tag,
      transitionOnUserGestures: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: CachedThumb(asset: widget.momentInfo.heroImage, fit: true, size: CachedThumb.big),
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
                              widget.momentInfo.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.momentInfo.subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )],
                    )
                  //Text(albumsToRender[index].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                alignment: Alignment.topRight,
                child:  Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          FloatingActionButton(
                            backgroundColor: AppConst.actionButtonColor,
                            heroTag: null,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.arrow_back_rounded),
                          ),
                        ],
                      ),
                    ),
                    FloatingActionButton(
                      backgroundColor: AppConst.actionButtonColor,
                      heroTag: null,
                      onPressed: () => addButtonPressed(albumsService, false),
                      child: const Icon(Icons.photo_library),
                    ),
                    const SizedBox(width: 5,),
                    FloatingActionButton(
                      backgroundColor: AppConst.actionButtonColor,
                      heroTag: null,
                      onPressed: () => addButtonPressed(albumsService, true),
                      child: const Icon(Icons.share_outlined),
                    ),
                  ],
                ),
              ),
            ]
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsService = Provider.of<AccountsService>(context);
    final albumsService = Provider.of<AlbumsService>(context);
    // final momentsService = Provider.of<MomentsService>(context);
    final actions = <Widget>[];
    actions.addAll(AssetActions(assets: assets, selected: selected, callback: () => setState(() {
      selected.clear();
    })).get());
    actions.addAll([
      const SizedBox(width: 10,),
      IconButton(
        onPressed: () => setState(() => selected.clear()),
        icon: const Icon(Icons.clear),
      ),
    ]);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _albumHeader(_headerHeight, albumsService),
          Expanded(
            child: FutureBuilder<List<AssetBaseModel>>(
              future: _getAssets(),
              builder: (ctx, snapshot) {
                if (snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final assetsToRender = snapshot.data!;
                return GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                    crossAxisCount: 3,
                  ),
                  itemCount: assetsToRender.length,
                  padding: const EdgeInsets.only(top: 2),
                  itemBuilder: (context, index) {
                    final gallery = SimpleGallery(assets: assetsToRender, currentIndex: index, heroVariation: widget.momentInfo.tag,);
                    return GestureDetector(
                      onLongPress: () => selectThumb(index),
                      onTap: () => selected.isNotEmpty
                          ? selectThumb(index)
                          : gallery.show(context),
                      child: Hero(
                        tag: assetsToRender[index].getHeroTag(widget.momentInfo.tag),
                        child: assetsToRender[index].getThumb(selected.contains(index)),
                      ),
                    );
                  }
                );
              }
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: Visibility(
        visible: selected.isNotEmpty,
        child: AssetActions.draw(actions),
      ),
    );
  }
}


