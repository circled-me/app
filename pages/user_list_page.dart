import 'package:app/app_consts.dart';
import 'package:app/models/user_model.dart';
import 'package:app/pages/settings_page.dart';
import 'package:app/services/user_service.dart';
import 'package:app/widget/edit_user_widget.dart';
import 'package:app/widget/ui.dart';
import '../models/account_model.dart';
import 'package:flutter/material.dart';

class UserListPage extends StatefulWidget {
  static const route = "/users";
  static final scrollController = ScrollController();
  final AccountModel account;
  const UserListPage(this.account, {Key? key}) : super(key: key);
  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {

  Future<List<UserModel>> _getUsers() async {
    print("loading users...");
    final us = UserService(widget.account);
    await us.loadFromAccount();
    return us.users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIHeroBar(
        tag: "Users-" + widget.account.identifier,
        title: "Users",
        onBack: () => SettingsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<UserModel>>(
        future: _getUsers(),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final usersToRender = snapshot.data!;
          if (usersToRender.isEmpty) {
            return Center(
              child: Text("No users yet", style: UIStyles.caption),
            );
          }
          return ListView.separated(
            controller: UserListPage.scrollController,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: usersToRender.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
            itemBuilder: (context, index) {
              final user = usersToRender[index];
              return UIListRow(
                icon: Icons.account_circle,
                title: user.name,
                subtitle: user.email,
                onTap: () => EditUserWidget.show(
                  user,
                  (success) => {if (success) setState(() {})},
                  context,
                  "",
                  "",
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        heroTag: null,
        foregroundColor: AppConst.mainColor,
        elevation: 2,
        onPressed: () => EditUserWidget.show(
          UserModel.empty(widget.account),
          (success) => {if (success) setState(() {})},
          context,
          "",
          "",
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
