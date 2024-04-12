import 'dart:convert';
import 'dart:io';
import 'package:app/models/account_model.dart';
import 'package:app/models/album_model.dart';
import 'package:app/models/moment_model.dart';
import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import 'listable_service.dart';

class MomentsService extends ChangeNotifier {
  final List<MomentModel> moments = [];

  static final MomentsService instance = MomentsService();
  static List<MomentModel> get getMoments => instance.moments;

  static void clear() async {
    instance.moments.clear();
  }

  static Future<void> loadFromAccount(AccountModel account) async {
    final response = await account.apiClient.get("/moment/list");
    if (response.status != 200) {
      return;
    }
    List<dynamic> parsedListJson = jsonDecode(response.body);
    for (var element in parsedListJson) {
      instance.moments.add(MomentModel.fromJson(account, element));
    }
    instance.notifyListeners();
  }
}
 