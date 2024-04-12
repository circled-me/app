import 'dart:convert';
import 'package:app/models/account_model.dart';
import 'package:app/models/album_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/models/tag_model.dart';
import 'package:app/services/accounts_service.dart';
import 'package:app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'listable_service.dart';

class TagService extends ChangeNotifier {
  TagService._();
  static final TagService instance = TagService._();

  // TODO: Delete this or move tags here?
}
 