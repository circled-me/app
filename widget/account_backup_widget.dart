import 'dart:convert';

import 'package:app/helpers/preferences.dart';
import 'package:app/helpers/toast.dart';
import 'package:app/widget/ui.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../models/account_model.dart';
import '../services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountBackupWidget extends StatefulWidget {
  const AccountBackupWidget({Key? key}) : super(key: key);

  @override
  State<AccountBackupWidget> createState() => _AccountBackupWidgetState();
}

class _AccountBackupWidgetState extends State<AccountBackupWidget> {
  List<String> _excludeAlbumIds = [];
  List<String> _excludeAlbumNames = [];
  bool _excludeAlbumsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadExcludeAlbums();
  }

  Future<void> _loadExcludeAlbums() async {
    final ids = await Preferences.getBackupExcludeAlbumIds();
    final present = await _resolvePresentAlbums(ids);
    final resolvedIds = present?.map((a) => a.id).toList() ?? ids;
    final resolvedNames = present?.map((a) => a.name).toList() ?? [];
    if (present != null && present.length != ids.length) {
      await Preferences.setBackupExcludeAlbumIds(resolvedIds);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _excludeAlbumIds = resolvedIds;
      _excludeAlbumNames = resolvedNames;
      _excludeAlbumsLoaded = true;
    });
  }

  /// Resolves saved album IDs to albums still on the device.
  /// Returns null if albums could not be listed (e.g. no permission).
  Future<List<_ExcludeAlbumItem>?> _resolvePresentAlbums(List<String> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    try {
      final authResult = await PhotoManager.requestPermissionExtend();
      if (!authResult.isAuth) {
        return null;
      }
      final paths = await PhotoManager.getAssetPathList(
        hasAll: true,
        type: RequestType.common,
      );
      final byId = {for (final path in paths) path.id: path.name};
      return [
        for (final id in ids)
          if (byId.containsKey(id))
            _ExcludeAlbumItem(id: id, name: byId[id]!),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> _openExcludeAlbumsPicker() async {
    final result = await showDialog<List<_ExcludeAlbumItem>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ExcludeAlbumsDialog(selectedIds: _excludeAlbumIds),
    );
    if (result == null || !mounted) {
      return;
    }
    final ids = result.map((a) => a.id).toList();
    final names = result.map((a) => a.name).toList();
    await Preferences.setBackupExcludeAlbumIds(ids);
    if (!mounted) {
      return;
    }
    setState(() {
      _excludeAlbumIds = ids;
      _excludeAlbumNames = names;
    });
    Toast.show(msg: "Exclude albums saved");
  }

  String _excludeAlbumsSummary() {
    if (_excludeAlbumIds.isEmpty) {
      return "None selected";
    }
    if (_excludeAlbumNames.isEmpty) {
      return "${_excludeAlbumIds.length} selected";
    }
    return _excludeAlbumNames.join(", ");
  }

  String _getMainStatus(BackupService backup) {
    switch (backup.status) {
      case BackupServiceStatus.complete:
        return "All " + backup.numTotal.toString() + " assets uploaded";
      case BackupServiceStatus.cancelling:
        return "Cancelling";
      case BackupServiceStatus.error:
        return "Error";
      case BackupServiceStatus.inProgress:
        return (backup.numTotal - backup.numPending).toString() + " of " + backup.numTotal.toString();
      case BackupServiceStatus.stopped:
      case BackupServiceStatus.pending:
        return "Backup Service";
    }
  }

  void share(AccountModel account) async {
    final response = await account.apiClient.get("/upload/share");
    final info = jsonDecode(response.body);
    if (response.status != 200) {
      Toast.show(msg: info["error"]);
      return;
    }
    Share.share(account.server + info["path"],
      subject: "Use this link to upload",
      sharePositionOrigin: const Rect.fromLTWH(50, 150, 10, 10), // TODO: Better coordinates
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupService>(
      builder: (context, backup, child) {
        double value = backup.numQueued > 0 && backup.numPending > 0 ? backup.numDone / backup.numQueued : 1;
        final canEditExclude = _excludeAlbumsLoaded && backup.isStopped;
        final statusDetail = backup.statusString != "" ? backup.statusString : "Idle";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getMainStatus(backup),
                          overflow: TextOverflow.ellipsis,
                          style: UIStyles.itemTitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          statusDetail,
                          overflow: TextOverflow.ellipsis,
                          style: UIStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            UIButtonRow(
              children: [
                UIPrimaryButton(
                  label: "Start",
                  icon: Icons.play_arrow,
                  onPressed: backup.isRunning || backup.status == BackupServiceStatus.cancelling
                      ? null
                      : () => backup.start(),
                ),
                UISecondaryButton(
                  label: "Stop",
                  icon: Icons.stop,
                  onPressed: backup.isStopped || backup.status == BackupServiceStatus.cancelling
                      ? null
                      : () => backup.cancel(),
                ),
              ],
            ),
            const SizedBox(height: UIStyles.sectionGap),
            Text("Exclude albums", style: UIStyles.itemTitle),
            const SizedBox(height: 4),
            Text(
              "Device albums to skip during backup",
              style: UIStyles.caption,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.22)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _excludeAlbumsLoaded ? _excludeAlbumsSummary() : "Loading...",
                      style: TextStyle(
                        fontSize: 14,
                        color: !_excludeAlbumsLoaded || _excludeAlbumIds.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: UIStyles.outlinedButton(),
                    onPressed: canEditExclude ? _openExcludeAlbumsPicker : null,
                    child: const Text("Select"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UIStyles.sectionGap),
            Text("Manual uploads", style: UIStyles.itemTitle),
            const SizedBox(height: 10),
            UIPrimaryButton(
              label: "Share Link",
              icon: Icons.link,
              expanded: true,
              onPressed: () => share(backup.account),
            ),
          ],
        );
      },
    );
  }
}

class _ExcludeAlbumItem {
  final String id;
  final String name;
  final int? count;

  _ExcludeAlbumItem({
    required this.id,
    required this.name,
    this.count,
  });
}

class _ExcludeAlbumsDialog extends StatefulWidget {
  const _ExcludeAlbumsDialog({required this.selectedIds});

  final List<String> selectedIds;

  @override
  State<_ExcludeAlbumsDialog> createState() => _ExcludeAlbumsDialogState();
}

class _ExcludeAlbumsDialogState extends State<_ExcludeAlbumsDialog> {
  bool _loading = true;
  String? _error;
  List<_ExcludeAlbumItem> _albums = [];
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedIds.toSet();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final authResult = await PhotoManager.requestPermissionExtend();
    if (!authResult.isAuth) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = "Photo permission is required to list albums";
      });
      PhotoManager.openSetting();
      return;
    }

    try {
      final paths = await PhotoManager.getAssetPathList(
        hasAll: true,
        type: RequestType.common,
      );
      final albums = <_ExcludeAlbumItem>[];
      final seenIds = <String>{};
      for (final path in paths) {
        if (path.isAll || seenIds.contains(path.id)) {
          continue;
        }
        seenIds.add(path.id);
        final count = await path.assetCountAsync;
        albums.add(_ExcludeAlbumItem(id: path.id, name: path.name, count: count));
      }
      albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _selectedIds.removeWhere((id) => !seenIds.contains(id));

      if (!mounted) {
        return;
      }
      setState(() {
        _albums = albums;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = "Couldn't load albums";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    Widget content;
    if (_loading) {
      content = const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      content = SizedBox(
        height: 120,
        child: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    } else if (_albums.isEmpty) {
      content = const SizedBox(
        height: 120,
        child: Center(child: Text("No albums found")),
      );
    } else {
      content = SizedBox(
        width: media.size.width,
        height: media.size.height * 0.5,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _albums.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          itemBuilder: (context, index) {
            final album = _albums[index];
            final subtitle = album.count != null ? "${album.count} items" : null;
            return CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              controlAffinity: ListTileControlAffinity.trailing,
              title: Text(album.name, style: UIStyles.itemTitle),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    )
                  : null,
              value: _selectedIds.contains(album.id),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedIds.add(album.id);
                  } else {
                    _selectedIds.remove(album.id);
                  }
                });
              },
            );
          },
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      insetPadding: const EdgeInsets.all(10),
      title: const Text("Exclude albums"),
      content: content,
      actions: <Widget>[
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  final selected = _albums
                      .where((a) => _selectedIds.contains(a.id))
                      .toList()
                    ..sort(
                      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );
                  Navigator.of(context).pop(selected);
                },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
