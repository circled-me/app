import 'package:app/app_consts.dart';
import 'package:app/pages/login_page.dart';
import 'package:app/services/backup_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/widget/account_widget.dart';

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
        //physics: const NeverScrollableScrollPhysics(),
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: w,
              height: h*0.1,
              decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("img/strip_hero2.png"),
                    fit: BoxFit.fill,
                  )
              ),
            ),
            Container(
              width: w,
              margin: const EdgeInsets.only(left: 15, right: 15),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Accounts", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10,),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 35, color: AppConst.mainColor,),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (context) => const LoginPage(closable: true,))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: allAccounts,
                    shrinkWrap: true,
                  ),
                ],
              )
           ),
        ]
      )
    )
    );
  }
}
