import 'dart:collection';
import 'package:app/app_consts.dart';
import 'package:app/helpers/asset.dart';
import 'package:app/helpers/asset_actions.dart';
import 'package:app/helpers/image_crop.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/face_model.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/services/user_service.dart';
import 'package:app/widget/person_select_widget.dart';
import 'package:app/helpers/toast.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../widget/simple_gallery_widget.dart';


import '../models/asset_model.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';




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

  static const double _baseHeaderHeight = 150;
  static const double _minHeaderHeight = 150;
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

  void downloadButtonPressed() async {
    Asset.downloadDialog(selected, assets, (result) {
      Toast.show(msg: result ? "All downloaded!" : "Couldn't downloaded some of the assets...");
      setState(() {
        selected.clear();
      });
    });
  }

  void editDialog() async {
    final people = await UserService.forAccount(widget.faceModel.asset.account).then((service) => service.getPeople());
    final rootContext = MyApp.navigatorKey.currentState!.context;
    // Use PersonSelectWidget to select person for the face
    PersonSelectWidget.show(
      context: rootContext,
      title: "Name",
      hint: ".. or select a person below",
      people: people,
      okButtonText: "Save",
      callback: (personId, personName) async {
        if (personId == -1) {
          // Create new person
          personId = await widget.faceModel.createPerson(personName);
          if (personId <= 0) {
            Toast.show(msg: "Could not create a new person", gravity: Toast.ToastGravityCenter);
            return;
          }
          // Reset the people list
          UserService.forAccount(widget.faceModel.asset.account).then((service) => service.resetPeople());
        }
        final success = await widget.faceModel.assignToPerson(personId);
        if (!success) {
          Toast.show(msg: "Could not save person for the face", gravity: Toast.ToastGravityCenter);
          return;
        }
        widget.faceModel.personName = personName;
        Navigator.of(rootContext).pop();
        setState(() {
          selected.clear();
        });
      });
  }
  void chooseHeroDialog(AssetModel newHero) async {
    // Choose default hero for the face
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
      // const SizedBox(width: 5,),
      // FloatingActionButton(
      //   backgroundColor: AppConst.actionButtonColor,
      //   heroTag: null,
      //   onPressed: () => {}, //Album.share(widget.albumInfo as AlbumModel),
      //   child: const Icon(Icons.share_outlined),
      // ),
    ];

    final topButtons = Container(
      padding: const EdgeInsets.all(7),
      alignment: Alignment.topRight,
      child:  Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: topButtonList
      ),
    );
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(215)
              ),
              child: Center(
                child: SizedBox(
                  width: height,
                  height: height,
                  child: FaceCropperWidget(faceRect: widget.faceModel.rect, asset: widget.faceModel.asset, width: 500, height: 500, shape: BoxShape.circle)
                ),
              ),
            ),
            Container(
              alignment: Alignment.bottomLeft,
              decoration:  BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(228),
                  ],
                  stops: const [0.55, 1],
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
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                              minimumSize: const Size(0, 0),
                            ),
                            onPressed: () => widget.faceModel.personName.isEmpty ? editDialog() : null,
                            child: Text(
                              widget.faceModel.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FutureBuilder(
                            future: futureAssets,
                            builder: (ctx, snapshot) {
                              if (snapshot.data == null) {
                                return const SizedBox();
                              }
                              final assets = snapshot.data as List<AssetModel>;
                              return Text(
                                assets.length.toString() + " photos and videos",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                    )],
                  )
              ),
            ),
            topButtons,
          ]
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
          onPressed: () => chooseHeroDialog(assets[selected.first]),
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 0,
      ),
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

