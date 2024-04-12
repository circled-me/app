import 'dart:convert';
import 'dart:collection';

import 'package:app/app_consts.dart';
import 'package:app/helpers/user.dart';
import 'package:app/models/group_user_model.dart';
import 'package:app/pages/group_feed_page.dart';
import 'package:app/services/user_service.dart';
import 'package:app/widget/empty_info_widget.dart';
import 'package:app/widget/multi_user_widget.dart';
import 'package:app/helpers/toast.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../models/group_model.dart';
import '../services/groups_service.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';


class GroupsListPage extends StatefulWidget {
  static final scrollController = ScrollController();

  const GroupsListPage({Key? key}) : super(key: key);

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  late List<GroupModel> groups = [];
  TextEditingController groupNameCtrl = TextEditingController();

  @override
  void dispose() {
    groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> createNewGroup(BuildContext context) async {
    // TODO: Select account
    AccountModel account;
    if (AccountsService.getAccounts.isEmpty) {
      Toast.show(msg: "You need to add an account first");
      return;
    } else if (AccountsService.getAccounts.length == 1) {
      account = AccountsService.getAccounts.first;
    } else {
      final selected = await User.switchAccount(AccountsService.getAccounts.first);
      if (selected == null) {
        return;
      }
      account = selected!;
    }
    // Fetch all users
    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()),);
    final usersService = await UserService.forAccount(account);
    Navigator.of(context, rootNavigator: true).pop();

    final members = <int, bool>{};
    final users = usersService.users;
    users.removeWhere((user) => user.id == account.userID);
    MultiUserWidget.show(
      users: users,
      members: members,
      callback: (newMembers) async {
        if (newMembers.isEmpty) {
          Toast.show(msg: "No users selected...");
          return;
        }
        List<GroupUser> members = [GroupUser(account.userID, usersService.userMap[account.userID]!.name, true)];
        for (final member in newMembers.entries) {
          members.add(GroupUser(member.key, usersService.userMap[member.key]!.name, member.value));
        }
        final newGroup = await GroupsService.instance.createGroup(account, members);
        if (newGroup == null) {
          Toast.show(msg: "Couldn't save group");
          return;
        } else {
          setState(() {});
          Navigator.of(context).pushNamed(GroupFeedPage.route, arguments: newGroup);
        }
      },
      context: context,
      title: "Create Group",
      hint: "Tap on a User's name to add them to the group. Twice to make them an admin.",
      okButtonText: "Create"
    );
  }

  Future<void> _updateGroupFavourite(GroupModel group) async {
    group.favourite = !group.favourite;
    await group.saveRemote();
    GroupsService.instance.reSortGroups();
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    final groupsService = Provider.of<GroupsService>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<GroupModel>>(
        future: groupsService.getGroups(),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final groupsToRender = snapshot.data!;
          if (groupsToRender.isEmpty) {
            return const Center(child: EmptyInfoWidget(Icons.group, "You haven't been invited\nto any groups yet..."));
          }
          return GridView.builder(
            controller: GroupsListPage.scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              crossAxisCount: 1,
              childAspectRatio: 5,
            ),
            itemCount: groupsToRender.length,
            itemBuilder: (context, index) {
              final unread = groupsToRender[index].hasUnread;
                final fontWeight = unread ? FontWeight.bold : FontWeight.normal;
                Widget rightWidget;
                if (unread) {
                  rightWidget = const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.message, color: Colors.black)
                  );
                } else {
                  rightWidget = IconButton(
                    color: Colors.black,
                    onPressed: () => _updateGroupFavourite(groupsToRender[index]),
                    icon: Icon(
                        groupsToRender[index].favourite ? Icons.star : Icons
                            .star_outline),
                  );
                }
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(GroupFeedPage.route, arguments: groupsToRender[index]),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 15, 7, 0),
                    color: Colors.white,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 7,
                            alignment: Alignment.centerLeft,
                            color: groupsToRender[index].getColour,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 9),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 5, left: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupsToRender[index].title(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: fontWeight,
                                    ),
                                  ),
                                  const SizedBox(height: 2,),
                                  Text(
                                    groupsToRender[index].messagePreview(),
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: fontWeight,
                                    ),
                                  ),
                                ],
                              )
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.only(right: 45),
                            child: Text(
                              groupsToRender[index].messageTime(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: fontWeight,
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child:  rightWidget,
                          ),
                        ]
                      ),
                    ),
                  ),
                );
            }
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: !AccountsService.getAccounts.first.canCreateGroups() ? null : FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: AppConst.mainColor,
        onPressed: () => createNewGroup(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}


