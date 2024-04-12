
import 'package:flutter/material.dart';

import '../models/account_model.dart';

abstract class ListableService {
  // addNew would be called whenever we have a new item to be added to the list.
  Future<int> addNew(AccountModel account, String name);

  List<DropdownMenuItem<int>> getItems();
}