import 'package:app/services/user_service.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';

class SelectOrAddUserWidget extends StatefulWidget {
  const SelectOrAddUserWidget({Key? key, required this.service, required this.callback, required this.title, required this.hint}) : super(key: key);
  final String title, hint;
  final UserService service;
  final Function(int, int) callback;

  static void show(UserService service, Function (int, int) callback, BuildContext context, String title, String hint) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SelectOrAddUserWidget(service: service, callback:callback, title: title, hint: hint,);
      },
    );
  }

  @override
  State<SelectOrAddUserWidget> createState() => _SelectOrAddUserWidgetState();
}

class _SelectOrAddUserWidgetState extends State<SelectOrAddUserWidget> {
  TextEditingController userNameCtrl = TextEditingController();
  int currentSelectedValue = 0;
  int currentSelectedMode = 0;

  @override
  void dispose() {
    userNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.service.getItems();
    items.removeWhere((element) => element.value!=null && element.value==widget.service.account.userID);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("The user will be able to see the album assets."),
          const SizedBox(height: 20,),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              hint: Text(widget.hint),
              value: currentSelectedValue > 0 ? currentSelectedValue : null,
              onChanged: (newValue) => setState(() => {
                currentSelectedValue = newValue ?? 0
              }),
              items: items,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: currentSelectedMode,
              onChanged: (newValue) => setState(() => {
                currentSelectedMode = newValue ?? 0
              }),
              items: const [
                DropdownMenuItem<int>(child: Text("User can add to the album"), value: 0,),
                DropdownMenuItem<int>(child: Text("User can only view album"), value: 1,),
              ],
            ),
          ),
        ],
      ),

      actions: <Widget>[
        TextButton(
          child: const Text('ADD'),
          onPressed: () {
            if (currentSelectedValue <= 0) {
              Toast.show(msg: "Please select user");
              return;
            }
            widget.callback(currentSelectedValue, currentSelectedMode);
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => widget.callback(-1, -1),
        ),
      ],
    );
  }
}
