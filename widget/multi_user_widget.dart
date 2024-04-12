import 'package:app/models/user_model.dart';
import 'package:app/services/user_service.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';

class MultiUserWidget extends StatefulWidget {
  const MultiUserWidget({Key? key, required this.users, required this.members, required this.callback, required this.title, required this.hint, required this.okButtonText}) : super(key: key);
  final String title, hint, okButtonText;
  final List<UserModel> users;
  final Map<int, bool> members; // id -> admin
  final Function(Map<int, bool> ) callback;

  static void show({required  List<UserModel> users, required  Map<int, bool> members, required Function (Map<int, bool> resultMembers) callback,
    required BuildContext context, required String title, required String hint, required String okButtonText}) {

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return MultiUserWidget(users: users, members: members, callback:callback, title: title, hint: hint, okButtonText:okButtonText);
      },
    );
  }

  @override
  State<MultiUserWidget> createState() => _MultiUserWidgetState();
}

class _MultiUserWidgetState extends State<MultiUserWidget> {
  final TextEditingController groupMemberCtrl = TextEditingController();

  @override
  void dispose() {
    groupMemberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundInputHint(ctrl: groupMemberCtrl, hintText: "Search", onChanged: (_) => setState(() {})),
            const SizedBox(height: 10),
            Text(widget.hint, style: const TextStyle(fontSize: 13, color: Colors.grey),),
            const SizedBox(height: 5),
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Theme(
                    data: ThemeData(canvasColor: Colors.black.withOpacity(0.5)),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 5.0,
                      children: widget.users.
                      where((user) => groupMemberCtrl.text=="" || user.name.toLowerCase().contains(groupMemberCtrl.text.toLowerCase())).
                      map((user) => FilterChip(
                        selectedColor: Colors.blue.withOpacity(0.8),
                        label: Text(user.name),
                        showCheckmark: false,
                        avatar: (widget.members[user.id]??false) ? const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20,) : null,
                        selected: widget.members.containsKey(user.id),
                        labelStyle: const TextStyle(color: Colors.white),
                        onSelected: (_) => setState(() {
                          if (!widget.members.containsKey(user.id)) {
                            widget.members[user.id] = false;
                          } else if (widget.members[user.id]!) {
                            widget.members.remove(user.id);
                          } else {
                            widget.members[user.id] = true;
                          }
                        }),
                      )
                      ).toList(),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(widget.okButtonText),
          onPressed: () {
            Navigator.of(context).pop();
            widget.callback(widget.members);
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
