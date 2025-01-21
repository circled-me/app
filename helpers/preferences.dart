import 'package:app/models/account_model.dart';
import 'package:app/services/accounts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const _gridSize = 'gridSize';
  static const _defaultAccount = 'defaultAccount';
  static final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  static Future<int> getGridSize(int defValue) async {
    final SharedPreferences prefs = await _prefs;
    final result = prefs.getInt(_gridSize);
    if (result != null) {
      return result;
    }
    await setGridSize(defValue);
    return defValue;
  }

  static Future<void> setGridSize(int value) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setInt(_gridSize, value);
  }

  static Future<AccountModel?> getDefaultAccount() async {
    final SharedPreferences prefs = await _prefs;
    final accId = prefs.getString(_defaultAccount);
    if (accId == null) {
      return null;
    }
    final tmp = AccountsService.getAccounts.where((account) => account.identifier == accId);
    if (tmp.isEmpty) {
      return null;
    }
    return tmp.first;
  }

  static Future<void> setDefaultAccount(AccountModel account) async {
    final SharedPreferences prefs = await _prefs;
    print("seeting: "+account.identifier);
    await prefs.setString(_defaultAccount, account.identifier);
  }
}