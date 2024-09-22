import 'dart:collection';
import 'dart:convert';
import 'package:app/app_consts.dart';
import 'package:app/helpers/asset.dart';
import 'package:app/helpers/asset_actions.dart';
import 'package:app/helpers/image_crop.dart';
import 'package:app/models/album_base_model.dart';
import 'package:app/models/album_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/face_model.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/services/assets_service.dart';
import 'package:app/services/user_service.dart';
import 'package:app/widget/multi_user_widget.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:app/helpers/toast.dart';
import 'package:provider/provider.dart';

import '../helpers/album.dart';
import '../helpers/user.dart';
import '../main.dart';
import '../widget/cached_thumb_widget.dart';
import '../widget/simple_gallery_widget.dart';


import '../models/asset_model.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';

import 'albums_page.dart';



class FaceThumbsPage extends StatefulWidget {
  static const route = "/face";
  final FaceModel faceModel;
  FaceThumbsPage({Key? key, required this.faceModel}) : super(key: key) {
    // faceModel.getAssets();
  }

  @override
  State<FaceThumbsPage> createState() => _FaceThumbsPageState();
}

class _FaceThumbsPageState extends State<FaceThumbsPage> {
  final Set<int> selected = SplayTreeSet<int>(); // Sorted set so we can remove items in order
  final List<AssetModel> assets = [];
  final _nameCtrl = TextEditingController();
  final _scrollController = ScrollController();

  static const double _baseHeaderHeight = 200;
  static const double _minHeaderHeight = 120;
  double _headerHeight = _baseHeaderHeight;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scrollController.removeListener(_userScrolled);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // _scrollController.addListener(_userScrolled);
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

  Future<List<AssetModel>> _getAssets() async {
    if (assets.isNotEmpty) {
      return assets;
    }
    final result = await widget.faceModel.getAssets();
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


  void favouriteButtonPressed() async {
    bool result = true;
    // Start from elements with higher index
    for (var index in selected.toList(growable: false).reversed) {
      if (!await assets[index].doFavourite(0)) {
        result = false;
      } else {
        selected.remove(index);
        assets.removeAt(index);
      }
    }
    if (result) {
      Toast.show(msg: "Now in your favourites album :)");
    } else {
      Toast.show(msg: "Couldn't favourite some of these...");
    }
    setState(() => () {});
   }


  void removeButtonPressed() async {
    // final rootContext = MyApp.navigatorKey.currentState!.context;
    // finalAction(bool shouldDelete) async {
    //   Navigator.of(rootContext).pop();
    //   if (!shouldDelete) {
    //     return;
    //   }
    //   final error = await removeAssets();
    //   if (error != "") {
    //     print("removeAssets() error: "+error);
    //     Toast.show(msg: "Couldn't remove some of the selected assets from the album. Make sure you have the right permissions to do so.");
    //     return;
    //   }
    //   setState(() => () {});
    // }
    // final warningText = selected.length>1
    //     ? "Are you sure you want to remove "+ selected.length.toString() +" assets from the album?"
    //     : "Are you sure you want to remove the selected asset from the album?";
    // showDialog(
    //   context: rootContext,
    //   barrierDismissible: true,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: const Text('Remove from album'),
    //       content: SingleChildScrollView(
    //         child: ListBody(
    //           children: [
    //             Text(warningText),
    //           ],
    //         ),
    //       ),
    //       actions: <Widget>[
    //         TextButton(
    //           child: const Text('Remove'),
    //           onPressed: () => finalAction(true),
    //         ),
    //         TextButton(
    //           child: const Text('Cancel'),
    //           onPressed: () => finalAction(false),
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  void downloadButtonPressed() async {
    Asset.downloadDialog(selected, assets, (result) {
      Toast.show(msg: result ? "All downloaded!" : "Couldn't downloaded some of the assets...");
      setState(() {
        selected.clear();
      });
    });
  }

  void editDialog() async {
    // final rootContext = MyApp.navigatorKey.currentState!.context;
    // _nameCtrl.text = widget.albumInfo.name;
    //
    // finalAction(bool shouldSave) async {
    //   if (!shouldSave) {
    //     Navigator.of(rootContext).pop();
    //     return;
    //   }
    //   final oldAlbumName = widget.albumInfo.name;
    //   widget.albumInfo.name = _nameCtrl.text;
    //   final response = await AlbumsService.save(widget.albumInfo);
    //   if (response.status != 200) {
    //     Toast.show(msg: "Couldn't save album name");
    //     widget.albumInfo.name = oldAlbumName; // restore
    //     return;
    //   }
    //   Navigator.of(rootContext).pop();
    //   setState(() => () {});
    // }
    //
    // showDialog(
    //   context: rootContext,
    //   barrierDismissible: true,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: const Text('Edit album'),
    //       content: SingleChildScrollView(
    //           child: RoundInputHint(ctrl: _nameCtrl, hintText: "Name",)
    //       ),
    //       actions: <Widget>[
    //         TextButton(
    //           child: const Text('Delete', style: TextStyle(color: AppConst.attentionColor)),
    //           onPressed: deleteDialog,
    //         ),
    //         TextButton(
    //           child: const Text('Save'),
    //           onPressed: () => finalAction(true),
    //         ),
    //         TextButton(
    //           child: const Text('Cancel'),
    //           onPressed: () => finalAction(false),
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  void chooseHeroDialog(AssetModel newHero) async {
    // final rootContext = MyApp.navigatorKey.currentState!.context;
    // finalAction(bool shouldSave) async {
    //   if (!shouldSave) {
    //     Navigator.of(rootContext).pop();
    //     return;
    //   }
    //   widget.albumInfo.heroAssetID = newHero.id;
    //   final response = await AlbumsService.save(widget.albumInfo);
    //   if (response.status != 200) {
    //     Toast.show(msg: "Couldn't save album cover");
    //     return;
    //   }
    //   Navigator.of(rootContext).pop();
    //   setState(() {
    //     selected.clear();
    //   });
    // }
    // showDialog(
    //   context: rootContext,
    //   barrierDismissible: true,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: const Text('Set album cover'),
    //       content: const SingleChildScrollView(
    //         child: ListBody(
    //           children: [
    //             Text("Do you want to set the selected photo as an album cover?"),
    //           ],
    //         ),
    //       ),
    //       actions: <Widget>[
    //         TextButton(
    //           child: const Text('Set'),
    //           onPressed: () => finalAction(true),
    //         ),
    //         TextButton(
    //           child: const Text('Cancel'),
    //           onPressed: () => finalAction(false),
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  void shareButtonPressed() async {
    if (await Album.shareAssets(selected.map((i) => assets[i] as AssetModel).toList())) {
      setState(() {
        selected.clear();
      });
    }
  }

  Widget _faceHeader(double height, Future<List<AssetModel>> futureAssets) {
    var topButtonList = <Widget>[
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
        onPressed: editDialog,
        child: const Icon(Icons.edit_outlined),
      ),
      const SizedBox(width: 5,),
      FloatingActionButton(
        backgroundColor: AppConst.actionButtonColor,
        heroTag: null,
        onPressed: () => {}, //Album.share(widget.albumInfo as AlbumModel),
        child: const Icon(Icons.share_outlined),
      ),
    ];

    final topButtons = Container(
      padding: const EdgeInsets.all(7),
      alignment: Alignment.topRight,
      child:  Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: topButtonList
      ),
    );
    return Hero(
      tag: widget.faceModel.tag,
      transitionOnUserGestures: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                // child: CachedThumb(asset: widget.faceModel.asset, fit: true, size: CachedThumb.big),
                child: FaceCropperWidget(faceRect: widget.faceModel.bigSquare, asset: widget.faceModel.asset, width: 550, shape: BoxShape.rectangle)
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
                              widget.faceModel.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // FutureBuilder(
                            //   future: futureAssets,
                            //   builder: (ctx, snapshot) {
                            //     if (snapshot.data == null) {
                            //       return const SizedBox();
                            //     }
                            //     final assets = snapshot.data as List<AssetModel>;
                            //     return Text(
                            //       assets.length.toString() + " assets",
                            //       style: const TextStyle(
                            //         color: Colors.white,
                            //         fontSize: 14,
                            //       ),
                            //     );
                            //   }
                            // ),
                          ],
                        ),
                      )],
                    )
                ),
              ),
              topButtons,
            ]
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final accountsService = Provider.of<AccountsService>(context);
    final albumsService = Provider.of<AlbumsService>(context);
    final actions = <Widget>[];
    if (selected.length == 1) {
      actions.add(
        IconButton(
          onPressed: () => chooseHeroDialog(assets[selected.first] as AssetModel),
          icon: const Icon(Icons.folder_special),
        ),
      );
    }
    if (actions.isNotEmpty) {
      actions.add(const SizedBox(width: 10));
    }
    actions.addAll(AssetActions(assets: assets, selected: selected, callback: () => setState(() {
      selected.clear();
    })).get());
    actions.addAll([
      const SizedBox(width: 10,),
      IconButton(
        onPressed: removeButtonPressed,
        icon: const Icon(Icons.remove_circle_outline),
      ),
    ]);
    if (selected.length > 1) {
      actions.addAll([
        const SizedBox(width: 10,),
        IconButton(
          onPressed: () => setState(() => selected.clear()),
          icon: const Icon(Icons.clear),
        ),
      ]);
    }
    var futureAssets = _getAssets();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _faceHeader(_headerHeight, futureAssets),
          Expanded(
            child: FutureBuilder<List<AssetBaseModel>>(
                future: futureAssets,
                builder: (ctx, snapshot) {
                  if (snapshot.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final assetsToRender = snapshot.data!;
                  return GridView.builder(
                      controller: _scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                        crossAxisCount: 3,
                      ),
                      itemCount: assetsToRender.length,
                      padding: const EdgeInsets.only(top: 2),
                      itemBuilder: (context, index) {
                        final gallery = SimpleGallery(assets: assetsToRender, currentIndex: index, heroVariation: widget.faceModel.tag,);
                        return GestureDetector(
                          onLongPress: () => selectThumb(index),
                          onTap: () => selected.isNotEmpty
                              ? selectThumb(index)
                              : gallery.show(context),
                          child: Hero(
                            tag: assetsToRender[index].getHeroTag(widget.faceModel.tag),
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

