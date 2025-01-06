import 'package:app/services/accounts_service.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';
import 'package:provider/provider.dart';

import '../services/listable_service.dart';

class SelectOrAddAlbumWidget extends StatefulWidget {
  const SelectOrAddAlbumWidget({Key? key, required this.service, required this.callback, required this.title, required this.hint}) : super(key: key);
  final String title, hint;
  final ListableService service;
  final Function(int) callback;

  static void show(ListableService service, Function (int) callback, BuildContext context, String title, String hint) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Consumer<AlbumsService>(
          builder: (context, value, child) {
            return SelectOrAddAlbumWidget(service: service, callback:callback, title: title, hint: hint,);
          },
        );
      },
    );
  }

  @override
  State<SelectOrAddAlbumWidget> createState() => _SelectOrAddAlbumWidgetState();
}

class _SelectOrAddAlbumWidgetState extends State<SelectOrAddAlbumWidget> {
  TextEditingController albumNameCtrl = TextEditingController();
  int currentSelectedValue = 0;

  @override
  void dispose() {
    albumNameCtrl.dispose();
    super.dispose();
  }

  void createNewDialog() {
    finalAction(bool shouldCreate) async {
      final newText = albumNameCtrl.text.trim();
      if (shouldCreate && newText == "") {
        Toast.show(msg: "Album name must not be empty");
        return;
      }
      Navigator.of(context).pop();
      if (!shouldCreate) {
        return;
      }
      // TODO: Make this drop-down too
      final account = AccountsService.getAccounts.first;
      final newValue = await widget.service.addNew(account, newText);
      if (newValue <= 0) {
        Toast.show(msg: "Couldn't create album.. Error "+newValue.toString());
        return;
      }
      widget.callback(newValue);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Album'),
          content: RoundInputHint(ctrl: albumNameCtrl, hintText: "Album Name", autoFocus: true,),
          actions: <Widget>[
            TextButton(
              child: const Text('Create'),
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
    final items = widget.service.getItems();
    items.add(const DropdownMenuItem<int>(
      child: Text("[New Album]"),
      value: 0,
    ));
    return AlertDialog(
      title: Text(widget.title),
      content: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isDense: false,
          hint: Text(widget.hint),
          value: currentSelectedValue > 0 ? currentSelectedValue : null,
          onChanged: (newValue) => setState(() {
            if (newValue!=null && newValue == 0) {
              createNewDialog();
            } else {
              currentSelectedValue = newValue ?? 0;
            };
          }),
          items: items,
        ),
      ),

      actions: <Widget>[
        TextButton(
          child: currentSelectedValue > 0 ? const Text('ADD') : const Text('NEW'),
          onPressed: () {
            if (currentSelectedValue <= 0) {
              createNewDialog();
              return;
            }
            widget.callback(currentSelectedValue);
          },
        ),
        // TextButton(
        //   child: const Text('Create New'),
        //   onPressed: createNewDialog,
        // ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => widget.callback(-1),
        ),
      ],
    );
  }
}
