
import 'dart:convert';

import 'package:app/helpers/album.dart';
import 'package:app/models/album_base_model.dart';
import 'package:app/models/external_album_model.dart';
import 'package:app/services/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'group_message_reaction_model.dart';

class GroupMessage {
  static const plain = 0;
  static const emoji = 1;
  static const album = 2;
  static const image = 3;
  static const imageURL = 4;

  final int id;
  final int groupID;
  final int clientStamp;
  final int serverStamp;
  final int userID;
  final String userName;
  final String content;
  final int replyTo;
  final int reactionTo;
  List<GroupMessageReaction> reactions = [];
  int _type = plain;
  GroupMessage(this.id, this.groupID, this.clientStamp, this.serverStamp, this.userID, this.userName, this.content, this.replyTo, this.reactionTo);

  static final _urlDetectorRegex = RegExp(r'(.*?)(https?://\S+)');
  static final _albumRegex = RegExp(r'^https?://[^/]+/w/album/[0-9a-zA-Z]+/$');
  static final _imageRegex = RegExp(r'^\[image:(http.+)\]$');
  static final _imageURL = RegExp(r'^https?://[^/]+/[^\\?]+\.(gif|png|jpg|jpeg|webp)(\\?\S*)?$');
  static final _emojiRegex = RegExp(r'(?:[\u00A9\u00AE\u203C\u2049\u2122\u2139\u2194-\u2199\u21A9-\u21AA\u231A-\u231B\u2328\u23CF\u23E9-\u23F3\u23F8-\u23FA\u24C2\u25AA-\u25AB\u25B6\u25C0\u25FB-\u25FE\u2600-\u2604\u260E\u2611\u2614-\u2615\u2618\u261D\u2620\u2622-\u2623\u2626\u262A\u262E-\u262F\u2638-\u263A\u2640\u2642\u2648-\u2653\u2660\u2663\u2665-\u2666\u2668\u267B\u267F\u2692-\u2697\u2699\u269B-\u269C\u26A0-\u26A1\u26AA-\u26AB\u26B0-\u26B1\u26BD-\u26BE\u26C4-\u26C5\u26C8\u26CE-\u26CF\u26D1\u26D3-\u26D4\u26E9-\u26EA\u26F0-\u26F5\u26F7-\u26FA\u26FD\u2702\u2705\u2708-\u270D\u270F\u2712\u2714\u2716\u271D\u2721\u2728\u2733-\u2734\u2744\u2747\u274C\u274E\u2753-\u2755\u2757\u2763-\u2764\u2795-\u2797\u27A1\u27B0\u27BF\u2934-\u2935\u2B05-\u2B07\u2B1B-\u2B1C\u2B50\u2B55\u3030\u303D\u3297\u3299]|(?:\uD83C[\uDC04\uDCCF\uDD70-\uDD71\uDD7E-\uDD7F\uDD8E\uDD91-\uDD9A\uDDE6-\uDDFF\uDE01-\uDE02\uDE1A\uDE2F\uDE32-\uDE3A\uDE50-\uDE51\uDF00-\uDF21\uDF24-\uDF93\uDF96-\uDF97\uDF99-\uDF9B\uDF9E-\uDFF0\uDFF3-\uDFF5\uDFF7-\uDFFF]|\uD83D[\uDC00-\uDCFD\uDCFF-\uDD3D\uDD49-\uDD4E\uDD50-\uDD67\uDD6F-\uDD70\uDD73-\uDD7A\uDD87\uDD8A-\uDD8D\uDD90\uDD95-\uDD96\uDDA4-\uDDA5\uDDA8\uDDB1-\uDDB2\uDDBC\uDDC2-\uDDC4\uDDD1-\uDDD3\uDDDC-\uDDDE\uDDE1\uDDE3\uDDE8\uDDEF\uDDF3\uDDFA-\uDE4F\uDE80-\uDEC5\uDECB-\uDED2\uDEE0-\uDEE5\uDEE9\uDEEB-\uDEEC\uDEF0\uDEF3-\uDEF6]|\uD83E[\uDD10-\uDD1E\uDD20-\uDD27\uDD30\uDD33-\uDD3A\uDD3C-\uDD3E\uDD40-\uDD45\uDD47-\uDD4B\uDD50-\uDD5E\uDD80-\uDD91\uDDC0]))');
  static final _albumCache = <String, ExternalAlbumModel>{};

  static GroupMessage fromJson(Map<String, dynamic> json) {
    final gm = GroupMessage(
        json["id"] as int,
        json["group_id"] as int,
        json["client_stamp"] as int,
        json["server_stamp"] as int,
        json["user_id"] as int,
        json["user_name"] as String,
        json["content"] as String,
        json["reply_to"] != null ? json["reply_to"] as int : 0,
        json["reaction_to"] != null ? json["reaction_to"] as int : 0,
    );
    if (_albumRegex.hasMatch(gm.content)) {
      gm._type = album;
    } else if (gm.content.characters.length < 4 && _emojiRegex.allMatches(gm.content).length >= gm.content.characters.length) {
      gm._type = emoji;
    } else if (_imageRegex.hasMatch(gm.content)) {
      gm._type = image;
    } else if (_imageURL.hasMatch(gm.content)) {
      gm._type = imageURL;
    }
    if (json.containsKey("reactions") && json["reactions"] is List) {
      for (final reaction in json["reactions"]) {
        gm.reactions.add(GroupMessageReaction.fromJson(reaction));
      }
    }
    return gm;
  }

  JSONObject toJson() {
    return {
      "id": id,
      "group_id": groupID,
      "client_stamp": clientStamp,
      "server_stamp": serverStamp,
      "user_id": userID,
      "user_name": userName,
      "content": content,
      "reply_to": replyTo,
      "reaction_to": reactionTo,
      "reactions": reactions.map((e) => e.toJson()).toList(),
    };
  }

  bool get isSpecial => _type != plain;

  Future<AlbumBaseModel?> _getExternalAlbum() async {
    final cacheID = groupID.toString()+"-"+id.toString()+"-"+content;
    if (_albumCache.containsKey(cacheID)) {
      return _albumCache[cacheID];
    }
    final response = await ApiClient.generic.get(content + "?format=json");
    if (response.status != 200) {
      return null;
    }
    final json = jsonDecode(response.body);
    return _albumCache[cacheID] = ExternalAlbumModel(cacheID, content, json);
  }

  String get shortPreview {
    if (content.length > 20) {
      return content.substring(0, 20) + "...";
    }
    return content;
  }

  Widget getContent(BuildContext context, double fontSize, Color fontColor) {
    if (_type == emoji) {
      return Text(content,
        style: TextStyle(fontSize: fontSize*2.5),
      );
    }
    if (_type == image || _type == imageURL) {
      var url;
      if (_type == imageURL) {
        url = content;
      } else {
        url = _imageRegex.firstMatch(content)!.group(1)!;
      }
      return Container(
        constraints: BoxConstraints(maxWidth: 230, maxHeight: 150),
        child: CachedNetworkImage(imageUrl: url, placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.grey.withOpacity(0.25)))),
      );
    }
    if (_type == album) {
      return FutureBuilder<AlbumBaseModel?>(
        future: _getExternalAlbum(),
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: SizedBox(
              height: 150,
              width: 250,
              child: snapshot.data == null
                ? const Center(child: CircularProgressIndicator())
                : Album.getPreview(context, snapshot.data!)
            ),
          );
        },
      );
    }
    // Plain text message...
    final matches =_urlDetectorRegex.allMatches(content);
    if (matches.isEmpty) {
      return Text(content,
        style: TextStyle(color: fontColor, fontSize: fontSize),
      );
    }
    final textPieces = <InlineSpan>[];
    final style = TextStyle(color: fontColor, fontSize: fontSize);
    final linkStyle = TextStyle(color: fontColor, fontSize: fontSize, decoration: TextDecoration.underline);
    int end = 0;
    for (final match in matches) {
      end = match.end;
      for (int i=1; i<match.groupCount+1; ++i) {
        final t = match.group(i);
        if (t != null) {
          if (i%2 == 1) {
            // Text
            textPieces.add(TextSpan(text: t, style: style));
          } else {
            // Link
            textPieces.add(TextSpan(
              style: linkStyle,
              text: t,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final uri = Uri.parse(t);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
                ,
            ),);
          }
        }
      }
    }
    if (end < content.length) {
      // Final piece of text left
      textPieces.add(TextSpan(text: content.substring(end), style: style));
    }
    return Text.rich(TextSpan(
      children: textPieces
    ));
  }
}
