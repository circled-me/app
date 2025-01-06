import 'dart:convert';
import 'dart:collection';

import 'package:app/app_consts.dart';
import 'package:app/pages/settings_page.dart';
import 'package:app/services/bucket_service.dart';
import 'package:app/widget/edit_bucket_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Hero(
          tag: "Storage-"+widget.account.identifier,
          transitionOnUserGestures: true,
          child: SizedBox(width: 120, height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(shape: const RoundedRectangleBorder()),
              onPressed: () => SettingsPage.navigatorKey.currentState!.popUntil((route) => route.isFirst),
              child: const Text("Storage", style: TextStyle(fontSize: 30, color: AppConst.fontColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<BucketModel>>(
        future: _getBuckets(),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final bucketsToRender = snapshot.data!;
          return GridView.builder(
            controller: BucketListPage.scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              crossAxisCount: 1,
              childAspectRatio: 5,
            ),
            itemCount: bucketsToRender.length,
            itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => EditBucketWidget.show(bucketsToRender[index], (success) => { if(success) setState(() {})}, context, "", ""),
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
                                  Icon(bucketsToRender[index].storageType == BucketModel.storageTypeFile ? Icons.storage : Icons.cloud_circle, size: 40, color: AppConst.mainColor,),
                                  const SizedBox(width: 12,),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bucketsToRender[index].name,
                                        style: const TextStyle(color: AppConst.mainColor, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      Text(bucketsToRender[index].storageType == BucketModel.storageTypeFile
                                          ? "Disk path: "+bucketsToRender[index].path
                                          : "S3 Bucket" + (bucketsToRender[index].path != "" ? ", prefix: "+bucketsToRender[index].path : " without prefix"),
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
        foregroundColor: AppConst.mainColor,
        heroTag: null,
        onPressed: () => EditBucketWidget.show(BucketModel.empty(widget.account), (success) => { if(success) setState(() {})}, context, "", ""),
        child: const Icon(Icons.add),
      ),
    );
  }
}


