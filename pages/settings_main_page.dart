import 'package:app/app_consts.dart';
import 'package:app/pages/login_page.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/widget/account_widget.dart';
import 'package:app/widget/ui.dart';

import '../services/accounts_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsMainPage extends StatefulWidget {
  const SettingsMainPage({Key? key}) : super(key: key);

  @override
  State<SettingsMainPage> createState() => _SettingsMainPageState();
}

class _SettingsMainPageState extends State<SettingsMainPage> with AutomaticKeepAliveClientMixin<SettingsMainPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final accountsService = Provider.of<AccountsService>(context);
    final websocketService = Provider.of<WebSocketService>(context);
    final allAccounts = <Widget>[];
    for (var account in accountsService.accounts) {
      allAccounts.add(AccountWidget(account: account, wsService: websocketService));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: w,
              height: h * 0.1,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("img/strip_hero2.png"),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                UIStyles.pagePadding,
                8,
                UIStyles.pagePadding,
                UIStyles.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text("Accounts", style: UIStyles.pageTitle),
                      ),
                      Material(
                        color: AppConst.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => const LoginPage(closable: true),
                            ),
                          ),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.add, size: 26, color: AppConst.mainColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    accountsService.accounts.isEmpty
                        ? "Add an account to get started"
                        : "Manage backup, users, and storage",
                    style: UIStyles.caption,
                  ),
                  const SizedBox(height: 18),
                  ...allAccounts,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
