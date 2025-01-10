import 'dart:convert';
import 'dart:collection';

import 'package:app/app_consts.dart';
import 'package:app/helpers/asset.dart';
import 'package:app/helpers/asset_actions.dart';
import 'package:app/helpers/preferences.dart';
import 'package:app/helpers/user.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/tag_model.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/services/assets_service.dart';
import 'package:app/widget/empty_info_widget.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:app/helpers/toast.dart';
import 'package:provider/provider.dart';

import '../helpers/album.dart';
import '../main.dart';
import '../models/account_model.dart';
import '../widget/simple_gallery_widget.dart';

import '../models/asset_model.dart';
import '../services/accounts_service.dart';

import 'package:flutter/material.dart';


class ThumbsPage extends StatefulWidget {
  static final scrollController = ScrollController();
  static late int index = -1;
  ThumbsPage(int idx, {Key? key}) : super(key: key) {
    index = idx;
  }

  @override
  State<ThumbsPage> createState() => _ThumbsPageState();
}

class _ThumbsPageState extends State<ThumbsPage> with AutomaticKeepAliveClientMixin<ThumbsPage> {
  final dragSelectController = DragSelectGridViewController();
  final TextEditingController tagSearchCtrl = TextEditingController();
  Set<int> get selected => dragSelectController.value.selectedIndexes;
  set selected(Set<int> newSet) {
    dragSelectController.value = Selection(newSet);
  }
  final List<AssetModel> assets = [];
  Function? searchBoxChanged;
  List<TagModel> filters = [];
  Set<int> assetFilter = SplayTreeSet<int>();
  bool searchDialogShown = false;
  bool selectionMode = false;
  Future<int>? gridSizeFuture = Preferences.getGridSize(4);
  int gridSize = 4;
  AccountModel? account;
  Future<AccountModel?>? accountFuture = Preferences.getDefaultAccount();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    dragSelectController.addListener(rebuild);
    tagSearchCtrl.addListener(searchBoxListener);
  }

  void rebuild() => setState(() {});
  @override
  void dispose() {
    dragSelectController.removeListener(rebuild);
    tagSearchCtrl.dispose();
    super.dispose();
  }

  void searchBoxListener() {
    if (searchBoxChanged != null) {
      searchBoxChanged!();
    }
  }

  Future<String> deleteAssets() async {
    final result = await AssetModel.deleteAtRemote(assets[selected.first].account, selected.map((i) => assets[i].id).toList(growable: false));
    final removedIndexes = SplayTreeSet<int>();

    for (final index in selected) {
      if (!result.failedIds.contains(assets[index].id)) {
        removedIndexes.add(index);
      }
    }
    for (final index in removedIndexes.toList(growable: false).reversed) {
      AssetsService.instance.removeAsset(assets[index]);
      assets.removeAt(index);
    }
    selected = {};
    return result.error;
  }

  void deleteButtonPressed() async {
    final rootContext = MyApp.navigatorKey.currentState!.context;
    finalAction(bool shouldDelete) async {
      Navigator.of(rootContext).pop();
      if (!shouldDelete) {
        return;
      }
      final error = await deleteAssets();
      if (error != "") {
        Toast.show(msg: "Couldn't delete some assets: "+error);
      }
      // TODO: Find better way to do this?
      await AssetsService.instance.reloadAccounts(AccountsService.instance);
      setState(() => () {
        selected = {};
      });
    }
    final warningText = selected.length>1
        ? "Are you sure you want to permanently delete "+ selected.length.toString() +" assets from your server library?"
        : "Are you sure you want to permanently delete the selected asset from your server library?";
    showDialog(
      context: rootContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(warningText),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppConst.attentionColor)),
              onPressed: () => finalAction(true),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => finalAction(false),
            ),
          ],
        );
      },
    );
  }

  void addButtonPressed(AlbumsService albumsService) async {
    Album.addToDialog(albumsService, selected, assets, (success, albumId) {
      selected = {};
    });
  }

  void searchDialog(AssetsService assetsService, AccountModel account, StateSetter parentSetState) async {
    final allTags = await assetsService.getTags(account);
    setState((){
      searchDialogShown = true;
    });
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Update the searchBoxChanged listener to call the newest setState
            searchBoxChanged = () => setState(() {});
            final word = tagSearchCtrl.text.toLowerCase();
            List<TagModel> tags = filters.toList();
            assetFilter = filters.isNotEmpty ? filters[0].assetIds : SplayTreeSet<int>();
            for (int i=1; i<filters.length; ++i) {
              assetFilter = assetFilter.intersection(filters[i].assetIds);
            }
            final filterSet = filters.toSet();
            for (final t in allTags) {
              if (filterSet.contains(t)) {
                continue;
              }
              if (word != "" && !t.value.toLowerCase().contains(word)) {
                continue;
              }
              if (assetFilter.isNotEmpty && assetFilter.intersection(t.assetIds).isEmpty) {
                continue;
              }
              tags.add(t);
            }
            return Dialog.fullscreen(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    RoundInputHint(ctrl: tagSearchCtrl,
                      hintText: "",
                      autoFocus: true,
                      icon: Icons.search,
                      onSubmitted: (value) {
                         if (value.replaceAll(" ", "") == "") {
                           Navigator.of(context).pop();
                           return;
                         }
                         for (final t in tags) {
                           if (!filterSet.contains(t)) {
                             setState(() {
                               tagSearchCtrl.clear();
                               filters.add(t);
                               filterSet.add(t);
                             });
                             parentSetState(() {
                               ThumbsPage.scrollController.animateTo(0,
                                 duration: const Duration(milliseconds: 500),
                                 curve: Curves.ease,
                               );
                             });
                             break;
                           }
                         }
                      },
                    ),
                    const SizedBox(height: 5.0),
                    Expanded(
                      child: Scrollbar(
                        interactive: true,
                        child: SingleChildScrollView(
                          child: Theme(
                            data: ThemeData(canvasColor: Colors.black.withOpacity(0.6)),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 5.0,
                              children: tags.take(100).map((TagModel value) {
                                final isSelected = filters.contains(value);
                                return FilterChip(
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 3.0),
                                  selectedColor: Colors.blue.withOpacity(0.6),
                                  label: Text(value.value),
                                  showCheckmark: false,
                                  avatar: value.getAvatar(Colors.white.withOpacity(0.7)),
                                  selected: isSelected,
                                  labelStyle: const TextStyle(color: Colors.white),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        filters.add(value);
                                        filterSet.add(value);
                                      } else {
                                        filters.remove(value);
                                        filterSet.remove(value);
                                      }
                                      // Clear current text
                                      tagSearchCtrl.text = "";
                                      parentSetState(() {
                                        ThumbsPage.scrollController.animateTo(0,
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.ease,
                                        );
                                      });
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          backgroundColor: AppConst.actionButtonColor,
                          heroTag: null,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Icon(Icons.check),
                        ),
                        const SizedBox(width: 15.0),
                        FloatingActionButton(
                          backgroundColor: AppConst.actionButtonColor,
                          heroTag: null,
                          onPressed: () {
                            filters = [];
                            assetFilter = SplayTreeSet<int>();
                            Navigator.of(context).pop();
                          },
                          child: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
        },
    ).then((value) => setState((){
      searchDialogShown = false;
    }));
  }

  void shareButtonPressed() async {
    if (await Album.shareAssets(selected.map((i) => assets[i]).toList())) {
      setState(() {
        selected = {};
      });
    }
  }

  // TODO: Duplicate code (put in helper class)
  void favouriteButtonPressed() async {
    bool result = true;
    // Start from elements with higher index
    for (var index in selected.toList(growable: false).reversed) {
      if (!await assets[index].doFavourite(0)) {
        result = false;
      } else {
        //selected.remove(index);
        assets.removeAt(index);
      }
    }
    selected = {};
    if (result) {
      Toast.show(msg: "Now in your favourites album :)");
    } else {
      Toast.show(msg: "Couldn't favourite some of these...");
    }
    setState(() => () {});
  }

  void downloadButtonPressed() async {
    Asset.downloadDialog(selected, assets, (result) {
      Toast.show(msg: result ? "All downloaded!" : "Couldn't downloaded some of the assets...");
      selected = {};
      setState(() => () {});
    });
  }

  void _switchAccount() async {
    final newAccount = await User.switchAccount(account);
    if (newAccount == null) {
      return;
    }
    setState(() {
      account = newAccount;
      Preferences.setDefaultAccount(account!);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final assetsService = Provider.of<AssetsService>(context);
    final albumsService = Provider.of<AlbumsService>(context);
    final accounts = AccountsService.getAccounts;

    print("rebuild assets");
    Future<List<AssetModel>> assetLoader = Future(() => []);
    if (accounts.isNotEmpty) {
      if (account == null || !accounts.contains(account)) {
        account = accounts.first;
      }
      assetLoader = assetsService.getAssets(account!, false);
    }
    List<Widget> actions = [];
    if (account != null) {
      if (selected.isEmpty && !selectionMode) {
        actions = [
          IconButton(
            onPressed: () => searchDialog(assetsService, account!, (fn) => setState(() => fn())),
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 10,),
          IconButton(
            onPressed: () => setState(() {
              selectionMode = true;
            }), // select mode
            icon: const Icon(Icons.check_box_outlined),
          ),
          const SizedBox(width: 10,),
          IconButton(
            onPressed: () => setState(() {
              gridSize = 3 + (gridSize - 3 + 1) % 4;
              Preferences.setGridSize(gridSize);
            }),
            icon: const Icon(Icons.grid_on),
          ),
          const SizedBox(width: 10,),
          IconButton(
            onPressed: () => Asset.uploadDialog(account!, null).then((value) => setState(() {
              AssetsService.instance.reloadAccounts(AccountsService.instance);
            })),
            icon: const Icon(Icons.add_photo_alternate),
          ),
          if (accounts.length > 1)
            const SizedBox(width: 10,),
          if (accounts.length > 1)
            IconButton(
              onPressed: _switchAccount,
              icon: const Icon(Icons.people),
            ),
        ];
        // Clear button for filters
        if (assetFilter.isNotEmpty) {
          actions.addAll([
            const SizedBox(width: 10,),
            IconButton(
              onPressed: () =>
                  setState(() {
                    filters = [];
                    assetFilter = SplayTreeSet<int>();
                    ThumbsPage.scrollController.animateTo(0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  }),
              icon: const Icon(Icons.clear),
            ),
          ]);
        } else {
          // Add refresh button
          actions.addAll([
            const SizedBox(width: 10,),
            IconButton(
              onPressed: () => setState(() {
                assetLoader = assetsService.getAssets(account!, true);
              }),
              icon: const Icon(Icons.refresh),
            ),
          ]);
        }
      } else {
        if (selected.isNotEmpty) {
          actions.addAll(AssetActions(assets: assets, selected: selected, callback: () => setState(() {
            selected = {};
          })).get());
          actions.addAll([
            const SizedBox(width: 10,),
            IconButton(
              onPressed: deleteButtonPressed,
              icon: const Icon(Icons.delete_outline),
            ),
          ]);
        }
        actions.addAll([
          const SizedBox(width: 10,),
          IconButton(
            onPressed: () =>
                setState(() {
                  selected = {};
                  selectionMode = false;
                }),
            icon: const Icon(Icons.clear),
          ),
        ]);
      }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<AssetModel>>(
        future: Future(() async {
          if (gridSizeFuture != null) {
            gridSize = await gridSizeFuture ?? gridSize;
            gridSizeFuture = null;
          }
          if (accountFuture != null) {
            account = await accountFuture;
            accountFuture = null;
            setState(() {});
          }
          return assetLoader;
        }),
        builder: (ctx, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const EmptyInfoWidget(Icons.photo, "No assets in your photo library.\nPlease upload or backup some photos and videos and they will appear here.");
          }
          assets.clear();
          for (final a in snapshot.data!) {
            if (assetFilter.isNotEmpty && !assetFilter.contains(a.id)) {
              continue;
            }
            assets.add(a);
          }
          return RawScrollbar(
            thumbColor: Colors.black.withOpacity(0.6),
            controller: ThumbsPage.scrollController,
            interactive: true,
            trackVisibility: true,
            thickness: 20,
            thumbVisibility: true,
            radius: const Radius.circular(7),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: DragSelectGridView(
                gridController: dragSelectController,
                scrollController: ThumbsPage.scrollController,
                triggerSelectionOnTap: selectionMode,
                reverse: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  crossAxisCount: gridSize,
                ),
                itemCount: assets.length,
                itemBuilder: (context, index, isSelected) {
                  final gallery = SimpleGallery(assets: assets, currentIndex: index, heroVariation: AssetBaseModel.heroBaseThumb, reverse: true,);
                  return GestureDetector(
                    onTap: () => gallery.show(context),
                    child: Hero(
                        tag: assets[index].getHeroTag(AssetBaseModel.heroBaseThumb),
                        child: assets[index].getThumb(isSelected),
                    ),
                  );
                }
              ),
            ),
          );
        }
      ),
      floatingActionButtonLocation: selected.isNotEmpty
        ? FloatingActionButtonLocation.miniCenterDocked
        : FloatingActionButtonLocation.miniCenterTop,
      floatingActionButton: Visibility(
        visible: !searchDialogShown,
        child: AssetActions.draw(actions),
      ),
    );
  }
}


