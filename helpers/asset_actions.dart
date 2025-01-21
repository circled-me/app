
import 'package:app/helpers/album.dart';
import 'package:app/helpers/asset.dart';
import 'package:app/helpers/toast.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/services/albums_service.dart';
import 'package:flutter/material.dart';

class AssetActions {
  final List<AssetBaseModel> assets;
  final Set<int> selected;
  final Function? callback;
  const AssetActions({required this.assets, required this.selected, this.callback});

  void _shareButtonPressed() async {
    if (await Album.shareAssets(selected.map((i) => assets[i] as AssetModel).toList())) {
      if (callback != null) {
        callback!();
      }
    }
  }

  void _favouriteButtonPressed() async {
    final containsAnyThatAreNotFavourite = selected.any((i) => !assets[i].isFavourite);
    for (final index in selected) {
      if (containsAnyThatAreNotFavourite) {
        // If any of the selected assets are not favourite, then we want to favourite them all
        await assets[index].doFavourite(0);
      } else {
        // If all of the selected assets are favourite, then we want to unfavourite them all
        await assets[index].doUnfavourite(0);
      }
    }
    if (callback != null) {
      callback!();
    }
  }

  void _downloadButtonPressed() async {
    Asset.downloadDialog(selected, assets, (result) {
      Toast.show(msg: result ? "All downloaded!" : "Couldn't downloaded some of the assets...");
      if (callback != null) {
        callback!();
      }
    });
  }

  void _addButtonPressed() async {
    Album.addToDialog(AlbumsService.instance, selected, assets.whereType<AssetModel>().toList(), (success, albumId) {
      if (callback != null) {
        callback!();
      }
    });
  }

  static Widget draw(List<Widget> actions) {
    return Theme(
      data: ThemeData(iconTheme: const IconThemeData(color: Colors.white)),
      child: Material(
        color: Colors.black.withOpacity(0.7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actions,
          ),
        ),
      ),
    );
  }

  List<Widget> get() {
    final result = <Widget>[];
    if (assets.isEmpty) {
      return result;
    }
    if (assets.first is AssetModel) {
      result.addAll([
        IconButton(
          onPressed: _shareButtonPressed,
          icon: const Icon(Icons.share_outlined),
        ),
        const SizedBox(width: 10,),
        IconButton(
          onPressed: _favouriteButtonPressed,
          icon: const Icon(Icons.favorite),
          color: selected.any((i) => !assets[i].isFavourite) ? null: Colors.red,
        ),
      ]);
      if ((assets.first as AssetModel).account.canUploadToServer()) {
        result.addAll([
          const SizedBox(width: 10,),
          IconButton(
            onPressed: _addButtonPressed,
            icon: const Icon(Icons.photo_library),
          ),
        ]);
      }
    }
    result.addAll([
      if (result.isNotEmpty)
        const SizedBox(width: 10,),
      IconButton(
        onPressed: _downloadButtonPressed,
        icon: const Icon(Icons.download),
      ),
    ]);
    return result;
  }
}