import 'dart:convert';

import 'package:app/models/bucket_model.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';

class EditBucketWidget extends StatefulWidget {
  const EditBucketWidget({Key? key, required this.bucket, required this.callback, required this.title, required this.hint}) : super(key: key);
  final String title, hint;
  final BucketModel bucket;
  final Function(bool) callback;

  static void show(BucketModel bucket, Function (bool) callback, BuildContext context, String title, String hint) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditBucketWidget(bucket: bucket, callback:callback, title: title, hint: hint,),
    );
  }

  @override
  State<EditBucketWidget> createState() => _SelectOrEditBucketWidgetState();
}

class _SelectOrEditBucketWidgetState extends State<EditBucketWidget> {
  TextEditingController bucketNameCtrl = TextEditingController();
  TextEditingController bucketPathCtrl = TextEditingController();
  TextEditingController bucketEndpointCtrl = TextEditingController();
  TextEditingController bucketS3KeyCtrl = TextEditingController();
  TextEditingController bucketS3SecretCtrl = TextEditingController();
  TextEditingController bucketS3RegionCtrl = TextEditingController();
  TextEditingController bucketS3EncryptionCtrl = TextEditingController();


  @override
  void initState() {
    super.initState();
    bucketNameCtrl.text = widget.bucket.name;
    bucketPathCtrl.text = widget.bucket.path;
    bucketEndpointCtrl.text = widget.bucket.endpoint;
    bucketS3KeyCtrl.text = widget.bucket.s3Key;
    bucketS3SecretCtrl.text = widget.bucket.s3Secret;
    bucketS3RegionCtrl.text = widget.bucket.s3Region;
    bucketS3EncryptionCtrl.text = widget.bucket.s3Encryption;
  }

  @override
  void dispose() {
    bucketNameCtrl.dispose();
    bucketPathCtrl.dispose();
    bucketEndpointCtrl.dispose();
    bucketS3KeyCtrl.dispose();
    bucketS3SecretCtrl.dispose();
    bucketS3RegionCtrl.dispose();
    bucketS3EncryptionCtrl.dispose();
    super.dispose();
  }

  void _bucketSave(BuildContext context) async {
    if (widget.bucket.assetPathPattern == "") {
      Toast.show(msg: "Please select Asset Path Format");
      return;
    }
    widget.bucket.name = bucketNameCtrl.text.trim();
    widget.bucket.path = bucketPathCtrl.text.trim();
    widget.bucket.endpoint = bucketEndpointCtrl.text.trim();
    widget.bucket.s3Key = bucketS3KeyCtrl.text.trim();
    widget.bucket.s3Secret = bucketS3SecretCtrl.text.trim();
    widget.bucket.s3Region = bucketS3RegionCtrl.text.trim();
    widget.bucket.s3Encryption = bucketS3EncryptionCtrl.text.trim();
    final result = await widget.bucket.save();
    if (result.status != 200) {
      final json = jsonDecode(result.body);
      Toast.show(msg: "Error: "+json["error"]);
      return;
    }
    Toast.show(msg: "Successfully saved bucket '"+widget.bucket.name+"'");
    Navigator.of(context).pop();
    widget.callback(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.all(10),
      title: const Text('Storage Bucket'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isDense: false,
                value: widget.bucket.storageType,
                onChanged: (newValue) => setState(() {
                  widget.bucket.storageType = newValue ?? 0;
                }),
                items: const [
                  DropdownMenuItem<int>(child: Text("Server Disk"), value: 0,),
                  DropdownMenuItem<int>(child: Text("S3 Bucket"), value: 1,),
                ],
              ),
            ),
            RoundInputHint(ctrl: bucketNameCtrl, hintText: widget.bucket.storageType == BucketModel.storageTypeS3 ? "Bucket Name" : "Display Name", autoFocus: true, compulsory: true,),
            const SizedBox(height: 12),
            RoundInputHint(ctrl: bucketPathCtrl, hintText: widget.bucket.storageType == BucketModel.storageTypeS3 ? "Prefix" : "Path", compulsory: widget.bucket.storageType == BucketModel.storageTypeFile,),
            const SizedBox(height: 12),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: false,
                value: widget.bucket.assetPathPattern,
                onChanged: (newValue) => setState(() {
                  widget.bucket.assetPathPattern = newValue ?? "";
                }),
                items: BucketModel.assetPathPatterns.entries.map((e) => DropdownMenuItem<String>(child: Text(e.value), value: e.key)).toList(growable: false),
              ),
            ),
            Visibility(
              visible: widget.bucket.storageType == BucketModel.storageTypeS3,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  RoundInputHint(ctrl: bucketS3KeyCtrl, hintText: "S3 Key", compulsory: true,),
                  const SizedBox(height: 12),
                  RoundInputHint(ctrl: bucketS3SecretCtrl, hintText: "S3 Secret", compulsory: true,),
                  const SizedBox(height: 12),
                  RoundInputHint(ctrl: bucketEndpointCtrl, hintText: "S3 Endpoint",),
                  const SizedBox(height: 12),
                  RoundInputHint(ctrl: bucketS3RegionCtrl, hintText: "S3 Region",),
                  const SizedBox(height: 12),
                  RoundInputHint(ctrl: bucketS3EncryptionCtrl, hintText: "S3 Encryption",),
                ],
              )
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Save'),
          onPressed: () => _bucketSave(context),
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () =>  Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
