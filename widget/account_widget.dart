import 'package:app/app_consts.dart';
import 'package:app/main.dart';
import 'package:app/models/user_model.dart';
import 'package:app/pages/bucket_list_page.dart';
import 'package:app/pages/user_list_page.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/widget/account_backup_widget.dart';
import 'package:expandable/expandable.dart';
import 'package:provider/provider.dart';
import '../services/accounts_service.dart';
import '../models/account_model.dart';
import '../pages/login_page.dart';

import 'package:flutter/material.dart';

class AccountWidget extends StatelessWidget {
  final AccountModel account;
  final WebSocketService wsService;
  AccountWidget({Key? key, required this.account, required this.wsService}) : super(key: key);
  final ExpandableController expController = ExpandableController(initialExpanded: true);

  List<Widget> getInfoHeader() {
    // var isOffline = wsService.isOffline(account);
    var result = <Widget>[
      Text(account.getDisplayName, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 8),
      // if (isOffline) Text("OFFLINE", style: TextStyle(color: AppConst.attentionColor)),
      // if (isOffline) SizedBox(height: 8)
    ];
    if (account.hasQuotaInfo && account.hasUsageInfo) {
      result.add(LinearProgressIndicator(value: account.bucketUsage/account.bucketQuota, backgroundColor: Colors.grey.withOpacity(0.3)));
      result.add(const SizedBox(height: 8));
      result.add(Text(account.getUsageAsString + " out of " + account.getQuotaAsString));
    } else if (account.hasUsageInfo) {
      result.add(LinearProgressIndicator(value: 0.7, backgroundColor: Colors.grey.withOpacity(0.3)));
      result.add(const SizedBox(height: 8));
      result.add(Text(account.getUsageAsString + " out of <unknown>"));
    }
    result.add(const SizedBox(height: 16));
    return result;
  }

  Future<void> logout() async {
    await account.logout();
    await AccountsService.removeAccount(account);
    if (AccountsService.getAccounts.isEmpty) {
      final rootContext = MyApp.navigatorKey.currentState!.context;
      Navigator.push(rootContext, MaterialPageRoute(fullscreenDialog: true, builder: (rootContext) => const LoginPage(closable: true,)));
    }
  }

  Future<void> actuallyDeleteAccount() async {
    final user = UserModel.from(account, id: account.userID);
    await user.delete();
  }
  void deleteAccountPressed() async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    finalAction(bool shouldDelete) async {
      Navigator.of(rootContext).pop();
      if (!shouldDelete) {
        return;
      }
      await actuallyDeleteAccount();
      await logout();
    }
    showDialog(
      context: rootContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Delete Account'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text("Are you sure you really want to permanently delete your account and all the data associated with it?"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppConst.attentionColor)),
              onPressed: () => finalAction(true),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => finalAction(false),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = account.isAdmin();
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: ExpandablePanel(
        controller: expController,
        header: Column(children: getInfoHeader(), crossAxisAlignment: CrossAxisAlignment.start,),
        collapsed: const Text("expand to see more...", style: TextStyle(fontSize: 14, color: Colors.grey)),
        expanded: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 100, height: 30,
                  child: ElevatedButton(
                    onPressed: logout,
                    child: const Text("Log Out"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Visibility(
                visible: AccountsService.hasBackup(account),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Backup", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ChangeNotifierProvider(
                        create: (ctx) => AccountsService.backupFor(account),
                        child: const AccountBackupWidget()
                    ),
                    const SizedBox(height: 15),
                  ],
                )
            ),
            if (isAdmin) const Text("Server", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            if (isAdmin) const SizedBox(height: 15),
            if (isAdmin) Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "Users-"+account.identifier,
                  transitionOnUserGestures: true,
                  child: SizedBox(width: 120, height: 30,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed(UserListPage.route, arguments: account),
                      child: const Text("Users"),
                    ),
                  ),
                ),
                const SizedBox(width: 20,),
                Hero(
                  tag: "Storage-"+account.identifier,
                  transitionOnUserGestures: true,
                  child: SizedBox(width: 120, height: 30,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed(BucketListPage.route, arguments: account, ),
                      child: const Text("Storage"),
                    ),
                  ),
                ),
              ]
            ),
            if (!isAdmin)
              const SizedBox(height: 20),
            if (!isAdmin)
              Center(
                child: TextButton(
                    onPressed: deleteAccountPressed,
                    child: const Text("Delete Account", style: TextStyle(color: AppConst.attentionColor))
                )
            ),
            const SizedBox(height: 20),
          ],
        ),
      )
    );
  }
}
