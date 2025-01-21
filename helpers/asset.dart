
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/helpers/toast.dart';
import 'package:app/main.dart';
import 'package:app/models/account_model.dart';
import 'package:app/models/album_model.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/services/assets_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:image/image.dart';

class Asset {
  static void downloadDialog(Set<int> selected, List<AssetBaseModel> assets, Function(bool) callback) async {
    final context = MyApp.navigatorKey.currentState!.context;
    Function? localSetState;
    int done=0, outOf=selected.length;
    bool cancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Downloading..."),
          content: StatefulBuilder(builder: (_, setState) {
            localSetState = setState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: done.toDouble()/outOf.toDouble(),
                ),
                const SizedBox(height: 10),
                Text(done.toString()+" out of "+outOf.toString()),
              ],
            );
          },),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                cancelled = true;
                Navigator.of(context).pop();
                callback(false);
              },
            ),
          ],
        );
      },
    );
    bool result = true;
    for (var index in selected) {
      if (cancelled) {
        return;
      }
      final download = await assets[index].download();
      if (download == null) {
        result = false;
      } else {
        // Check if it is already locally available
        // final asset = await AssetEntity.fromId(assets[index].deviceId);
        // if (asset != null && await asset.isLocallyAvailable()) {
        //   print("Locally available");
        // }
        if (assets[index].isImage) {
          await PhotoManager.editor.saveImage(download.readAsBytesSync(), title: assets[index].name, filename: assets[index].name);
        } else if (assets[index].isVideo) {
          await PhotoManager.editor.saveVideo(download, title: assets[index].name);
        } else {
          Toast.show(msg: assets[index].name + ": this asset type cannot be downloaded");
        }
      }
      done++;
      if (localSetState != null) {
        localSetState!((){});
      }
    }
    Navigator.of(context).pop();
    callback(result);
  }

  static Future<void> uploadDialog(AccountModel account, AlbumModel? albumInfo) async {
    final files = await ImagePicker().pickMultipleMedia();
    if (files.isEmpty) {
      return;
    }
    final context = MyApp.navigatorKey.currentState!.context;
    Function? localSetState;
    int done=0, outOf=files.length;
    bool cancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Uploading..."),
          content: StatefulBuilder(builder: (_, setState) {
            localSetState = setState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: done.toDouble()/outOf.toDouble(),
                ),
                const SizedBox(height: 10),
                Text(done.toString()+" out of "+outOf.toString()),
              ],
            );
          },),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                cancelled = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    final newIds = await uploadNewAssets(account, files, () {
      done++;
      if (localSetState != null) {
        localSetState!((){});
      }
      return !cancelled;
    });
    if (newIds.length != files.length) {
      Toast.show(msg: "Some assets could not be uploaded");
    }
    if (albumInfo != null) {
      final multiResponse = await AssetModel.addToAlbum(account, albumInfo.id, newIds);
      if (multiResponse.status != 200) {
        print("Multi result error:"+multiResponse.status.toString()+"; "+multiResponse.error);
      }
      if (multiResponse.status != 200) {
        Toast.show(msg: "Some assets could not be added to the album");
      } else {
        Toast.show(msg: "All assets added to the album. Also in your Library");
      }
    }
    Navigator.of(context).pop();
  }

  static Future<Uint8List?> _getThumbFor(XFile file) {
    final lcName = file.name.toLowerCase();
    if (lcName.endsWith(".mp4") || lcName.endsWith(".mov")) {
      return vt.VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 1280,
        quality: 90,
      );
    }
    final image = decodeImage(File(file.path).readAsBytesSync());
    if (image == null) {
      return Future(() => null);
    }
    int w,h;
    if (image.width > image.height) {
      w = 1280;
      h = 1280*image.height~/image.width;
    } else {
      h = 1280;
      w = 1280*image.width~/image.height;
    }
    final thumb = copyResize(image, width: w, height: h);
    return Future(() => encodeJpg(thumb, quality: 90));
  }

  static Future<List<int>> uploadNewAssets(AccountModel account, List<XFile> files, Function progress) async {
    final ids = <int>[];
    for (final file in files) {
      final params = {
        "id": file.name,
        "name": "Upload"+(ids.length+1).toString()+path.extension(file.path),
        "mimetype": file.mimeType??"",
        "created": DateTime.now().toUtc().millisecondsSinceEpoch~/1000,
        "favourite": false,
      };
      final metaResult = await account.apiClient.post("/backup/meta-data", body: jsonEncode(params));
      if (metaResult.status != 200) {
        return ids;
      }
      final Map<String, dynamic> metaURIs = jsonDecode(metaResult.body);
      final fileReader = File(file.path);
      Future<Uint8List?> thumbFuture = _getThumbFor(file);

      final result = await account.apiClient.streamedPut(metaURIs["uri"]!.toString(), fileReader, headers: {"Content-Type" : metaURIs["mime_type"]!.toString()});
      if (result.statusCode != 200) {
        print("Upload error: "+result.statusCode.toString());
        return ids;
      }
      final assetSize = await fileReader.length();
      var thumbnailData = await thumbFuture;
      if (thumbnailData != null) {
        final thumbResult = await account.apiClient.put(
            metaURIs["thumb"]!.toString(), body: thumbnailData,
            headers: {"Content-Type": "image/jpeg"});
        if (thumbResult.status != 200) {
          thumbnailData = Uint8List(0);
        }
      }
      final confirmation = await account.apiClient.post("/backup/confirm", params: {
        "id": metaURIs["id"]!.toString(),
        "size": assetSize.toString(),
        "thumb_size": (thumbnailData ?? Uint32List(0)).length.toString(),
      });
      if (confirmation.status != 200) {
        print("Confirmation error: "+confirmation.status.toString());
        return ids;
      }
      ids.add(metaURIs["id"] as int);
      final asset = AssetModel(account, metaURIs["id"] as int, params["name"] as String, account.userID, DateTime.now().toUtc().millisecondsSinceEpoch~/1000,
          (file.mimeType??"").startsWith("video/") ? AssetBaseModel.typeVideo : AssetBaseModel.typeImage, "", null, null, "", assetSize);
      AssetsService.instance.addAsset(asset);
      if (!progress()) {
        return ids;
      }
    }
    AssetsService.instance.notifyListeners();
    return ids;
  }
}