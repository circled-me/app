import 'dart:convert';
import 'dart:collection';

import 'package:app/helpers/album.dart';
import 'package:app/models/album_model.dart';
import 'package:app/pages/album_thumbs_page.dart';
import 'package:app/services/moments_service.dart';
import 'package:app/widget/empty_info_widget.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../models/moment_model.dart';
import '../widget/cached_thumb_widget.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';

import 'moment_thumbs_page.dart';


class MomentListPage extends StatefulWidget {
  static final scrollController = ScrollController();

  const MomentListPage({Key? key}) : super(key: key);

  @override
  State<MomentListPage> createState() => _MomentListPageState();
}

class _MomentListPageState extends State<MomentListPage> {
  late List<MomentModel> albums = [];

  Future<List<MomentModel>> _getMoments(List<AccountModel> accounts) async {
    MomentsService.clear();
    for (final account in accounts) {
      try {
        await MomentsService.loadFromAccount(account);
      } catch (e) {
        print("exception for MomentsService.loadFromAccount(account): "+account.server+", err: "+e.toString());
      }
    }
    return albums = MomentsService.getMoments;
  }

  @override
  Widget build(BuildContext context) {
    final accountsService = Provider.of<AccountsService>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<MomentModel>>(
        future: _getMoments(accountsService.accounts),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final momentsToRender = snapshot.data!;
          if (momentsToRender.isEmpty) {
            return const EmptyInfoWidget(Icons.map_outlined, "No places found in your photo library. Please upload photos/videos that have location information.");
          }
          return GridView.builder(
            controller: MomentListPage.scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              crossAxisCount: 1,
              childAspectRatio: 2,
            ),
            itemCount: momentsToRender.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Album.getPreview(context, momentsToRender[index]),
            )
          );
        }
      ),
    );
  }
}


