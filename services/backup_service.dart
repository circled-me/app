import 'dart:convert';
import 'dart:io';

import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/services/assets_service.dart';

import 'api_client.dart';
import '../models/account_model.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

enum BackupServiceStatus {
  stopped, pending, inProgress, error, complete, cancelling
}

class BackupService extends ChangeNotifier {
  static const _uriBackupCheck = "/backup/check";
  static const _uriBackupMetaData = "/backup/meta-data";
  static const _uriConfirmData = "/backup/confirm";

  BackupServiceStatus _status = BackupServiceStatus.stopped;
  BackupServiceStatus get status => _status;

  final AccountModel account;
  int numTotal = 0;
  int numQueued = 0;
  int numPending = 0;
  int numDone = 0;
  String statusString = "";

  BackupService(this.account);

  void cancel() {
    _status = BackupServiceStatus.cancelling;
    notifyListeners();
  }

  bool get isRunning {
    return _status == BackupServiceStatus.pending
        || _status == BackupServiceStatus.inProgress;
  }

  bool get isStopped {
    return _status == BackupServiceStatus.stopped
        || _status == BackupServiceStatus.error
        || _status == BackupServiceStatus.complete;
  }

  void _setStatus(BackupServiceStatus newStatus, String message) {
    _status = newStatus;
    statusString = message;
    notifyListeners();
  }

  Future<void> start() async {
    if (isRunning) {
      return;
    }
    _setStatus(BackupServiceStatus.pending, "Pending...");
    List<AssetEntity> allAssets;

    var authResult = await PhotoManager.requestPermissionExtend();
    if (authResult.isAuth) {
      await PhotoManager.clearFileCache();
      List<AssetPathEntity> list = await PhotoManager.getAssetPathList(
          hasAll: true, onlyAll: true, type: RequestType.common);
      if (list.isEmpty) {
        _setStatus(BackupServiceStatus.error, "No albums found");
        return;
      }
      // TODO: Import albums too?!
      int totalAsset = await list[0].assetCountAsync;
      allAssets = await list[0].getAssetListRange(start: 0, end: totalAsset);
    } else {
      PhotoManager.openSetting();
      _setStatus(BackupServiceStatus.error, "No Photo Permission");
      return;
    }

    ApiClient api = account.apiClient;
    List<String> currentIDs = [];
    for (final a in allAssets) {
      currentIDs.add(a.id);
    }
    final result = await api.post(_uriBackupCheck, body: jsonEncode({"ids": currentIDs}));
    if (result.status != 200) {
      print(result.body);
      _setStatus(BackupServiceStatus.error, "Error with backup server");
      return;
    }
    final List<String> presentIDs = jsonDecode(result.body).cast<String>();
    numDone = 0;
    numTotal = allAssets.length;
    numQueued = numPending = numTotal - presentIDs.length;
    _setStatus(BackupServiceStatus.inProgress, "Starting backup...");

    Set<String> toSkip = {};
    for (final id in presentIDs) {
      toSkip.add(id);
    }
    // Backup all pending assets
    File? file;
    for (final asset in allAssets) {
      if (_status == BackupServiceStatus.cancelling) {
        // We need to cancel now
        _setStatus(BackupServiceStatus.stopped, "Cancelled");
        break;
      }
      if (toSkip.contains(asset.id)) {
        continue;
      }
      print(asset);
      numPending--;
      numDone++;

      try {
        if (asset.type == AssetType.video) {
          file = await asset.originFile;
        } else {
          file = await asset.originFile.timeout(const Duration(seconds: 5));
        }
        if (file == null) {
          continue;
        }
        final title = await asset.titleAsync;
        _setStatus(BackupServiceStatus.inProgress, "Uploading "+title+"...");

        final mimeType = await asset.mimeTypeAsync;
        final params = {
          "id": asset.id,
          "name": title,
          "mimetype": mimeType ?? "",
          "created": asset.createDateTime.toUtc().millisecondsSinceEpoch~/1000,
          "favourite": asset.isFavorite,
          "width": asset.width,
          "height": asset.height,
          "duration": asset.videoDuration.inSeconds.toInt(),
          "time_offset": asset.createDateTime.timeZoneOffset.inSeconds,
        };
        // On iOS asset.latitude and asset.longitude always seem to have values, so ignoring 0,0
        if (asset.latitude != null && asset.longitude != null && asset.latitude != 0 && asset.longitude != 0) {
          params.addAll({"lat":asset.latitude!, "long":asset.longitude!});
        }
        // Create meta-data upload request
        final metaResult = await api.post(_uriBackupMetaData, body: jsonEncode(params));
        if (metaResult.status == 403) {
          // This asset type is not allowed
          continue;
        }
        if (metaResult.status != 200) {
          throw Exception(metaResult);
        }
        final Map<String, dynamic> metaURIs = jsonDecode(metaResult.body);
        print(metaURIs);
        // Upload the actual asset to the URI provided by the server
        final resultPromise = api.streamedPut(metaURIs["uri"]!.toString(), file, headers: {"Content-Type" : metaURIs["mime_type"]!.toString()});
        // Generate thumbnail at the same time
        var thumbnailData = await asset.thumbnailDataWithSize(const ThumbnailSize(1280, 1280), quality: 90);
        final result = await resultPromise;
        if (result.statusCode == 200 && thumbnailData != null) {
          // Now upload thumbnail
          final thumbResult = await api.put(metaURIs["thumb"]!.toString(), body:thumbnailData, headers: {"Content-Type" : "image/jpeg"});
          if (thumbResult.status != 200) {
            thumbnailData.clear();
          }
        }
        // Finally send confirmation
        int assetSize = 0;
        if (result.statusCode == 200) {
          // Async call (on purpose)
          assetSize = await file.length();
          api.post(_uriConfirmData, params: {
            "id": metaURIs["id"]!.toString(),
            "size": assetSize.toString(),
            "thumb_size": thumbnailData != null && thumbnailData.isNotEmpty ? thumbnailData.length.toString() : "0",
          });
          // TODO: Revert to add asset to the Photos tab, needed?
          // AssetsService.instance.addAsset(AssetModel(account, metaURIs["id"] as int, title, account.userID, asset.createDateTime.millisecondsSinceEpoch~/1000,
          //     mimeType!.startsWith("image/") ? AssetBaseModel.typeImage : AssetBaseModel.typeVideo, asset.id, asset.latitude, asset.longitude, null, assetSize));
        }
      }
      on Exception catch(e) {
        print("Exception: "+e.toString());
        _setStatus(BackupServiceStatus.error, "Got error: "+e.toString());
      }
      finally {
        if (Platform.isIOS) {
          file?.deleteSync();
        }
      }
    }
    // TODO: Is this ok?
    await AssetsService.instance.reloadAccounts(AccountsService.instance);
    if (_status != BackupServiceStatus.error && numPending == 0) {
      _setStatus(BackupServiceStatus.complete, "All backed up");
    }
  }
}