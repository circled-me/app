import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TagModel {
  static const tagTypePlace  = 1;
  static const tagTypePerson = 2;
  static const tagTypeYear   = 3;
  static const tagTypeMonth  = 4;
  static const tagTypeDay    = 5;
  static const tagTypeSeason = 6;
  static const tagTypeType   = 7;
  static const tagTypeFavourite   = 8;
  static const tagTypeAlbum   = 9;
  static final tagTypes = [
    "Place",
    "Person",
    "Year",
    "Month",
    "Day",
    "Season",
    "Type",
    "Is",
    "Album",
  ];

  final int tagType;
  final String value;
  final SplayTreeSet<int> assetIds;

  TagModel(this.tagType, this.value, this.assetIds);

  static TagModel fromJson(Map<String, dynamic> json) {
    return TagModel(json["t"], json["v"], SplayTreeSet.from(json["a"]));
  }

  Widget? getAvatar(Color color) {
    switch(tagType) {
      case tagTypePlace: return Icon(Icons.place, color: color,);
      case tagTypePerson: return Icon(Icons.person, color: color,);
      case tagTypeYear:
      case tagTypeMonth:
      case tagTypeDay:
      case tagTypeSeason: return Icon(Icons.calendar_today_rounded, size: 18, color: color);
      case tagTypeType: return Icon(Icons.play_circle_outline, color: color,); // Only video?
      case tagTypeFavourite: return Icon(Icons.favorite, color: color,);
      case tagTypeAlbum: return Icon(Icons.photo_library, color: color,);
      default: null;
    }
  }
  @override
  String toString() {
    return tagTypes[tagType-1] + ":" + value;
  }
}
