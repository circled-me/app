import 'package:app/app_consts.dart';
import 'package:app/models/user_model.dart';
import 'package:app/pages/settings_page.dart';
import 'package:app/services/user_service.dart';
import 'package:app/widget/edit_user_widget.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Hero(
          tag: "Users-"+widget.account.identifier,
          transitionOnUserGestures: true,
          child: SizedBox(width: 120, height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(shape: const RoundedRectangleBorder()),
              onPressed: () => SettingsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst),
              child: const Text("Users", style: TextStyle(fontSize: 30, color: AppConst.fontColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<UserModel>>(
        future: _getUsers(),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final usersToRender = snapshot.data!;
          return GridView.builder(
            controller: UserListPage.scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              crossAxisCount: 1,
              childAspectRatio: 5,
            ),
            itemCount: usersToRender.length,
            itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => EditUserWidget.show(usersToRender[index], (success) => { if(success) setState(() {})}, context, "", ""),
                  child: Stack(
                    children: [
                      Container(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 0, left: 10),
                          child: Stack(
                            children: [Positioned(
                              left: 2,
                              bottom: 5,
                              child: Row(
                                children: [
                                  const Icon(Icons.account_circle, size: 40, color: AppConst.mainColor,),
                                  const SizedBox(width: 12,),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        usersToRender[index].name,
                                        style: const TextStyle(color: AppConst.mainColor, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        usersToRender[index].email,
                                        style: const TextStyle(color: AppConst.mainColor, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )],
                          )
                        ),
                      ),
                    ]
                  ),
                );
            }
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        heroTag: null,
        foregroundColor: AppConst.mainColor,
        onPressed: () => EditUserWidget.show(UserModel.empty(widget.account), (success) => { if(success) setState(() {})}, context, "", ""),
        child: const Icon(Icons.add),
      ),
    );
  }
}
