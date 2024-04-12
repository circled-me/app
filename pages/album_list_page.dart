import 'package:app/helpers/album.dart';
import 'package:app/models/album_model.dart';
import 'package:app/pages/album_thumbs_page.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/widget/empty_info_widget.dart';
import 'package:provider/provider.dart';
import '../widget/cached_thumb_widget.dart';
import '../services/accounts_service.dart';
import 'package:flutter/material.dart';


class AlbumListPage extends StatefulWidget {
  static final scrollController = ScrollController();

  const AlbumListPage({Key? key}) : super(key: key);

  @override
  State<AlbumListPage> createState() => _AlbumListPageState();
}

class _AlbumListPageState extends State<AlbumListPage> {

  Future<List<AlbumModel>> _getAlbums(AlbumsService albumsService, AccountsService accountsService) async {
    await albumsService.reloadAccounts(accountsService, false);
    return albumsService.albums;
  }

  @override
  Widget build(BuildContext context) {
    final accountsService = Provider.of<AccountsService>(context);
    final albumsService = Provider.of<AlbumsService>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<AlbumModel>>(
        future: _getAlbums(albumsService, accountsService),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final albumsToRender = snapshot.data!;
          if (albumsToRender.isEmpty) {
            return const EmptyInfoWidget(Icons.photo_library, "No albums. You can create albums by selecting photos/videos from your library and click on the album button.");
          }
          return GridView.builder(
            controller: AlbumListPage.scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              crossAxisCount: 1,
              childAspectRatio: 2,
            ),
            itemCount: albumsToRender.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Album.getPreview(context, albumsToRender[index]),
            )
          );
        }
      ),
    );
  }
}


