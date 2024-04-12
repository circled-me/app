import 'dart:convert';

import 'package:app/models/user_model.dart';
import 'package:app/services/bucket_service.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';
import 'package:share_plus/share_plus.dart';

class EditUserWidget extends StatefulWidget {
  const EditUserWidget({Key? key, required this.user, required this.callback, required this.title, required this.hint}) : super(key: key);
  final String title, hint;
  final UserModel user;
  final Function(bool) callback;

  static void show(UserModel user, Function (bool) callback, BuildContext context, String title, String hint) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditUserWidget(user: user, callback:callback, title: title, hint: hint,),
    );
  }

  @override
  State<EditUserWidget> createState() => _SelectOrEditUserWidgetState();
}

class _SelectOrEditUserWidgetState extends State<EditUserWidget> {
  TextEditingController userNameCtrl = TextEditingController();
  TextEditingController userEmailCtrl = TextEditingController();
  TextEditingController userQuotaCtrl = TextEditingController();
  Future<BucketService>? bucketServiceFuture;

  @override
  void dispose() {
    userNameCtrl.dispose();
    userEmailCtrl.dispose();
    userQuotaCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    bucketServiceFuture = BucketService.from(widget.user.account);
    userNameCtrl.text = widget.user.name;
    userEmailCtrl.text = widget.user.email;
    userQuotaCtrl.text = widget.user.quota > 0 ? widget.user.quota.toString() : "";
  }

  String _getInvitation(String token) {
    final server = widget.user.account.server.replaceFirst("https://", "");
    return "https://app.circled.me/invite/"+ Uri.encodeComponent(server) + "/" + token;
  }
  void _userSave(BuildContext context) async {
    widget.user.name = userNameCtrl.text.trim();
    widget.user.email = userEmailCtrl.text.trim();
    final newQuota = int.tryParse(userQuotaCtrl.text);
    if (userQuotaCtrl.text.isNotEmpty) {
      if (newQuota != null) {
        widget.user.quota = newQuota!;
      } else {
        Toast.show(msg: "Quota should be blank or a number");
        return;
      }
    } else {
      widget.user.quota = 0;
    }
    final result = await widget.user.save();
    final json = jsonDecode(result.body);
    if (result.status != 200) {
      Toast.show(msg: json["error"]);
      return;
    }
    if (json["token"]!=null && json["token"]!="") {
      Share.share(_getInvitation(json["token"]),
        subject:"Join our circled.me community server",
        sharePositionOrigin: const Rect.fromLTWH(50, 150, 10, 10), // TODO: Better coordinates
      );
    }
    Toast.show(msg: "Successfully saved user '"+widget.user.name+"'");
    Navigator.of(context).pop();
    widget.callback(true);
  }

  void _showInvite(BuildContext context) async {
    final result = await widget.user.reinvite();
    final json = jsonDecode(result.body);
    if (result.status != 200) {
      Toast.show(msg: json["error"]);
      return;
    }
    if (json["token"]!=null && json["token"]!="") {
      Share.share(_getInvitation(json["token"]),
        subject:"Re-join our circled.me community server",
        sharePositionOrigin: const Rect.fromLTWH(50, 150, 10, 10), // TODO: Better coordinates
      );
    }
    Toast.show(msg: "Re-invited user '"+widget.user.name+"'");
    Navigator.of(context).pop();
    widget.callback(true);
  }

  Widget _buildCheckbox(String title, String hint, int value, {bool enabled=true}) {
    return SizedBox(height: 60,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(hint),
        enabled: enabled,
        value: widget.user.permissions.contains(value),
        onChanged: (nv) => setState(() {
          if (nv!=null && nv && !widget.user.permissions.contains(value)) {
            widget.user.permissions.add(value);
          } else {
            widget.user.permissions.remove(value);
            if (value == UserModel.permissionPhotoUpload) {
              // permissionPhotoBackup is dependant on permissionPhotoUpload
              widget.user.permissions.remove(UserModel.permissionPhotoBackup);
            }
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BucketService>(
      future: bucketServiceFuture,
      builder: (ctx, snapshot) {
        if (snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final bucketService = snapshot.data!;
        return AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.all(10),
          title: const Text('User'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.user.id>0) RoundInputHint(ctrl: userEmailCtrl, hintText: "Login", autoFocus: true, disabled: true, compulsory: false,),
                if (widget.user.id>0) const SizedBox(height: 12),
                RoundInputHint(ctrl: userNameCtrl, hintText: "Name", autoFocus: true, compulsory: true,),
                const SizedBox(height: 12),
                RoundInputHint(ctrl: userQuotaCtrl, hintText: "Quota in MB (blank for unlimited)", keyboard: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text("Storage:"),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      isDense: false,
                      value: widget.user.bucket == 0 ? null : widget.user.bucket,
                      onChanged: (newValue) => setState(() => widget.user.bucket = newValue ?? 0),
                      items: bucketService.getItems(),
                    ),
                  ],
                ),
                _buildCheckbox("Admin", "Has all permissions", UserModel.permissionAdmin),
                _buildCheckbox("Upload assets", "Can upload and create albums", UserModel.permissionPhotoUpload),
                _buildCheckbox("Asset backup", "Can backup", UserModel.permissionPhotoBackup, enabled: widget.user.permissions.contains(UserModel.permissionPhotoUpload)),
                _buildCheckbox("Create groups", "Can create new groups", UserModel.permissionCanCreateGroups),
              ],
            ),
          ),
          actions: <Widget>[
            if (widget.user.id > 0) TextButton(
              child: const Text('Re-Invite'),
              onPressed: () => _showInvite(context),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => _userSave(context),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      }
    );
  }
}
