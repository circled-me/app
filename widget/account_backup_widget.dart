import 'dart:convert';

import 'package:app/helpers/toast.dart';
import 'package:share_plus/share_plus.dart';

import '../models/account_model.dart';
import '../services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountBackupWidget extends StatelessWidget {
  const AccountBackupWidget({Key? key}) : super(key: key);

  String _getMainStatus(BackupService backup) {
    switch (backup.status) {
      case BackupServiceStatus.complete:
        return "All "+backup.numTotal.toString() + " assets uploaded";
      case BackupServiceStatus.cancelling:
        return "Cancelling";
      case BackupServiceStatus.error:
        return "Error";
      case BackupServiceStatus.inProgress:
        return (backup.numTotal-backup.numPending).toString()+" of "+backup.numTotal.toString();
    }
    return "Backup Service";
  }

  void share(AccountModel account) async {
    final response = await account.apiClient.get("/upload/share");
    final info = jsonDecode(response.body);
    if (response.status != 200) {
      Toast.show(msg: info["error"]);
      return;
    }
    Share.share(account.server+info["path"],
      subject:"Use this link to upload",
      sharePositionOrigin: const Rect.fromLTWH(50, 150, 10, 10), // TODO: Better coordinates
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Consumer<BackupService>(
        builder: (context, backup, child) {
          // TODO
          double value = backup.numQueued>0 && backup.numPending>0 ? backup.numDone / backup.numQueued : 1;
          return Column(
            children: [
              Row(
                children: [
                  CircularProgressIndicator(value: value, strokeWidth: 7,),
                  const SizedBox(width: 15,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getMainStatus(backup), overflow: TextOverflow.fade, style: const TextStyle(fontSize: 18),),
                      Text(backup.statusString != "" ? backup.statusString : "Idle", overflow: TextOverflow.fade, style: const TextStyle(fontSize: 14, color: Colors.grey),),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 120, height: 30,
                    child: ElevatedButton(
                      onPressed: backup.isRunning || backup.status == BackupServiceStatus.cancelling ? null : () => backup.start(),
                      child: const Text("Start"),
                    ),
                  ),
                  const SizedBox(width: 20,),
                  SizedBox(width: 120, height: 30,
                    child: ElevatedButton(
                      onPressed: backup.isStopped || backup.status == BackupServiceStatus.cancelling ? null : () => backup.cancel(),
                      child: const Text("Stop"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Row(
                children: [
                  Text("Manual Uploads", overflow: TextOverflow.fade, style: TextStyle(fontSize: 18),),
                ]
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 120, height: 30,
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text("From App"),
                    ),
                  ),
                  const SizedBox(width: 20,),
                  SizedBox(width: 120, height: 30,
                    child: ElevatedButton(
                      onPressed: () => share(backup.account),
                      child: const Text("Share Link"),
                    ),
                  ),
                ],
              )
            ],
          );
        },
      )
    );
  }
}
