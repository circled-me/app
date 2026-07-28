import 'package:app/app_consts.dart';
import 'package:app/pages/settings_page.dart';
import 'package:app/services/bucket_service.dart';
import 'package:app/widget/edit_bucket_widget.dart';
import 'package:app/widget/settings_ui.dart';
import '../models/account_model.dart';
import '../models/bucket_model.dart';
import 'package:flutter/material.dart';

class BucketListPage extends StatefulWidget {
  static const route = "/buckets";
  static final scrollController = ScrollController();
  final AccountModel account;
  const BucketListPage(this.account, {Key? key}) : super(key: key);
  @override
  State<BucketListPage> createState() => _BucketListPageState();
}

class _BucketListPageState extends State<BucketListPage> {

  Future<List<BucketModel>> _getBuckets() async {
    final bs = await BucketService.from(widget.account);
    return bs.buckets;
  }

  String _subtitleFor(BucketModel bucket) {
    if (bucket.storageType == BucketModel.storageTypeFile) {
      return "Disk path: " + bucket.path;
    }
    return "S3 Bucket" + (bucket.path != "" ? ", prefix: " + bucket.path : " without prefix");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SettingsHeroBar(
        tag: "Storage-" + widget.account.identifier,
        title: "Storage",
        onBack: () => SettingsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<BucketModel>>(
        future: _getBuckets(),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final bucketsToRender = snapshot.data!;
          if (bucketsToRender.isEmpty) {
            return Center(
              child: Text("No storage buckets yet", style: SettingsStyles.caption),
            );
          }
          return ListView.separated(
            controller: BucketListPage.scrollController,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: bucketsToRender.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
            itemBuilder: (context, index) {
              final bucket = bucketsToRender[index];
              return SettingsListRow(
                icon: bucket.storageType == BucketModel.storageTypeFile
                    ? Icons.storage
                    : Icons.cloud_circle,
                title: bucket.name,
                subtitle: _subtitleFor(bucket),
                onTap: () => EditBucketWidget.show(
                  bucket,
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
        foregroundColor: AppConst.mainColor,
        heroTag: null,
        elevation: 2,
        onPressed: () => EditBucketWidget.show(
          BucketModel.empty(widget.account),
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
