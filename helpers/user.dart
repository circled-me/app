import 'dart:convert';

import 'package:app/app_consts.dart';
import 'package:app/services/api_client.dart';
import 'package:app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../models/account_model.dart';
import '../models/album_model.dart';
import '../models/asset_model.dart';
import '../services/accounts_service.dart';
import '../services/albums_service.dart';
import '../services/listable_service.dart';
import '../widget/select_add_album_widget.dart';
import '../widget/select_add_user_widget.dart';

class User {


  static String _addProtocol(String url) {
    // If the url starts with a number and a dot, it's probably a local IP address so we prefix it with http:// by default
    if (url.startsWith(RegExp("[0-9]+\\."))) {
      return "http://"+url;
    }
    if (!url.toLowerCase().startsWith("https://") && !url.toLowerCase().startsWith("http://")) {
      return "https://"+url;
    }
    return url;
  }

  // Returns error, or empty string on success
  static Future<String> login(String server, token, email, password, bool newServer) async {
    final serverUrl = _addProtocol(server);
    final apiClient = ApiClient(serverUrl);
    final response = await apiClient.post("/user/login", body: jsonEncode({
        "token": token,
        "email": email,
        "password": password,
        "new": newServer,
      }),
    ).timeout(const Duration(seconds: 10));
    print(response.status);
    print(response.body);
    print(response.cookie);

    if (response.status == 200 && response.cookie?.name == "token") {
      JSONObject json = jsonDecode(response.body);
      json["server"] = serverUrl;
      json["token"] = response.cookie?.value;
      json["autoBackup"] = false;
      final account = AccountModel.fromJson(json);
      await AccountsService.addAccount(account);
      return "";
    } else {
      JSONObject json = jsonDecode(response.body);
      return json["error"];
    }
  }

  static void peopleDialog(AccountModel account, Function(int, int) callback) async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    final usersService = await UserService.forAccount(account);

    finalAction(int userId, mode) async {
      Navigator.of(rootContext).pop();
      callback(userId, mode);
      if (userId > 0) {
        usersService.notifyListeners();
      }
    }
    SelectOrAddUserWidget.show(usersService, finalAction, rootContext, "Add New Contributor", "Select user");
  }

  static Future<AccountModel?> switchAccount(AccountModel? account) async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    return showDialog(
      context: rootContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Select Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<AccountModel>(
                    isDense: false,
                    value: account,
                    onChanged: (newValue) => setState(() {
                      account = newValue;
                      Navigator.of(context).pop(account);
                    }),
                    items: AccountsService.getAccounts.map((e) =>
                        DropdownMenuItem<AccountModel>(
                            child: Text(e.getDisplayName, style:const TextStyle(color: AppConst.mainColor)),
                            value: e
                        )).toList(growable: false),
                  ),
                )
              ],
            ),
            actions: <Widget>[
              TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(null)
              ),
            ],
          ),
        );
      },
    );
  }
}
