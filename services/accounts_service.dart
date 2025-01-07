import 'dart:convert';
import 'package:app/helpers/toast.dart';
import 'package:flutter/material.dart';
import '../storage.dart';
import '../models/account_model.dart';
import '../services/backup_service.dart';

class AccountsService extends ChangeNotifier {
  final List<AccountModel> accounts = [];
  final Map<AccountModel, BackupService> backupServices = {};
  final _storage = Storage("accounts");

  AccountsService._();

  static final AccountsService instance = AccountsService._();
  static List<AccountModel> get getAccounts => instance.accounts;
  bool get isEmpty => accounts.isEmpty;
  int get numAccounts => accounts.length;

  Future<void> saveAccounts() async {
    await _storage.write(jsonEncode(accounts));
  }

  static bool hasBackup(AccountModel account) {
    return instance.backupServices.containsKey(account);
  }

  static BackupService backupFor(AccountModel account) {
    return instance.backupServices[account]!;
  }

  static void updated() {
    print("Accounts::updated");
    instance.notifyListeners();
  }

  bool hasAnyBackup() {
    for (final account in accounts) {
      if (account.hasBackup()) {
        return true;
      }
    }
    return false;
  }

  bool hasAnyPhotoUpload() {
    for (final account in accounts) {
      if (account.canUploadToServer()) {
        return true;
      }
    }
    return false;
  }

  Future<void> _addAccount(AccountModel account) async {
    // Check if account is still valid
    if (!await account.updateStatus()) {
      print("No connection to server.\nAccount: ${account.getDisplayName}");
      Toast.show(msg: "No connection to server.\nAccount: ${account.getDisplayName}", timeInSecForIosWeb: 5,gravity: Toast.ToastGravityCenter);
      return;
    }
    accounts.add(account);
    if (account.hasBackup()) {
      final backup = BackupService(account);
      backupServices[account] = backup;
      // backup.start();
    }
    await instance.saveAccounts();
  }

  Future<void> _removeAccount(AccountModel account) async {
    if (accounts.remove(account)
        && account.hasBackup()
        && backupServices[account] != null) {
      backupServices[account]!.cancel();
      backupServices.remove(account);
    }
    await instance.saveAccounts();
  }

  static Future<void> addAccount(AccountModel account) async {
    print("Accounts::addAccount");
    await instance._addAccount(account);
    instance.notifyListeners();
  }

  static Future<void> removeAccount(AccountModel account) async {
    print("Accounts::removeAccount");
    instance._removeAccount(account);
    instance.notifyListeners();
  }

  static Future<void> loadAccounts() async {
    print("Accounts::loadAccounts");
    var val = await instance._storage.read() ?? "";
    if (val == "") {
      instance.notifyListeners();
      return;
    }
    List<dynamic> parsedListJson = jsonDecode(val);
    for (var element in parsedListJson) {
      final account = AccountModel.fromJson(element);
      print("Accounts::elem: '$parsedListJson'");
      await instance._addAccount(account);
    }
    print("Accounts loaded");
    instance.notifyListeners();
  }

  static void pushTokenReceived(bool enabled) async {
    print("Push enabled: $enabled");
    if (!enabled) {
      return;
    }
    for (final account in instance.accounts) {
      await account.updateStatus();
    }
  }
 }
 