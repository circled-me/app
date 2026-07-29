import 'package:app/app_consts.dart';
import 'package:app/main.dart';
import 'package:app/models/user_model.dart';
import 'package:app/pages/bucket_list_page.dart';
import 'package:app/pages/user_list_page.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/widget/account_backup_widget.dart';
import 'package:app/widget/ui.dart';
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
    var result = <Widget>[
      Text(account.getDisplayName, style: UIStyles.itemTitle),
      const SizedBox(height: 6),
    ];
    if (account.hasQuotaInfo && account.hasUsageInfo) {
      result.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: account.bucketUsage / account.bucketQuota,
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
        ),
      );
      result.add(const SizedBox(height: 8));
      result.add(Text(
        account.getUsageAsString + " out of " + account.getQuotaAsString,
        style: UIStyles.caption,
      ));
    } else if (account.hasUsageInfo) {
      result.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.7,
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
        ),
      );
      result.add(const SizedBox(height: 8));
      result.add(Text(
        account.getUsageAsString + " out of <unknown>",
        style: UIStyles.caption,
      ));
    }
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
              child: const Text('Cancel'),
              onPressed: () => finalAction(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppConst.attentionColor)),
              onPressed: () => finalAction(true),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = account.isAdmin();
    return UICard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: ExpandablePanel(
        controller: expController,
        theme: const ExpandableThemeData(
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          tapHeaderToExpand: true,
          hasIcon: true,
          iconColor: Colors.grey,
          iconPadding: EdgeInsets.only(left: 8, right: 4),
          expandIcon: Icons.expand_more,
          collapseIcon: Icons.expand_less,
        ),
        header: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: getInfoHeader(),
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text("Tap to manage this account", style: UIStyles.caption),
        ),
        expanded: Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1),
              const SizedBox(height: 16),
              UISecondaryButton(
                label: "Log Out",
                expanded: true,
                icon: Icons.logout,
                onPressed: logout,
              ),
              if (AccountsService.hasBackup(account)) ...[
                const SizedBox(height: UIStyles.sectionGap),
                const UISectionHeader(title: "Backup"),
                ChangeNotifierProvider(
                  create: (ctx) => AccountsService.backupFor(account),
                  child: const AccountBackupWidget(),
                ),
              ],
              if (isAdmin) ...[
                const SizedBox(height: UIStyles.sectionGap),
                const UISectionHeader(title: "Server"),
                UIButtonRow(
                  children: [
                    Hero(
                      tag: "Users-" + account.identifier,
                      transitionOnUserGestures: true,
                      child: UIPrimaryButton(
                        label: "Users",
                        icon: Icons.people_outline,
                        onPressed: () => Navigator.of(context).pushNamed(UserListPage.route, arguments: account),
                      ),
                    ),
                    Hero(
                      tag: "Storage-" + account.identifier,
                      transitionOnUserGestures: true,
                      child: UIPrimaryButton(
                        label: "Storage",
                        icon: Icons.cloud_outlined,
                        onPressed: () => Navigator.of(context).pushNamed(BucketListPage.route, arguments: account),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isAdmin) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: deleteAccountPressed,
                    child: const Text(
                      "Delete Account",
                      style: TextStyle(color: AppConst.attentionColor),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
