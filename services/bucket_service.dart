import 'dart:collection';
import 'dart:convert';
import 'package:app/models/account_model.dart';
import 'package:flutter/material.dart';
import '../models/bucket_model.dart';
import 'listable_service.dart';

class BucketService extends ChangeNotifier implements ListableService {
  final List<BucketModel> buckets = [];
  final AccountModel account;
  static Map<AccountModel, BucketService> instances = HashMap();
  BucketService(this.account);

  static Future<BucketService> from(AccountModel account) async {
    instances.putIfAbsent(account, () => BucketService(account));
    // TODO: Review this below (slow - reloads from server every time)
    await instances[account]!._load();
    return instances[account]!;
  }

  Future<List<BucketModel>> _load() async {
    buckets.clear();
    print("loading buckets...");
    final response = await account.apiClient.get("/bucket/list");
    if (response.status != 200) {
      return [];
    }
    List<dynamic> parsedListJson = jsonDecode(response.body);
    for (var element in parsedListJson) {
      buckets.add(BucketModel.fromJson(account, element));
    }
    notifyListeners();
    return buckets;
  }

  @override
  Future<int> addNew(AccountModel account, String name) async {
    // Not implemented
    return 0;
  }

  @override
  List<DropdownMenuItem<int>> getItems() {
    return buckets.map((b) => DropdownMenuItem<int>(
      value: b.id,
      child: Text(b.name),
    )).toList();
  }

}
 