import 'dart:async';

import 'package:app/custom_cache.dart';
import 'package:app/helpers/asset_actions.dart';
import 'package:app/helpers/toast.dart';
import 'package:app/main.dart';
import 'package:app/models/asset_base_model.dart';
import 'package:app/models/asset_model.dart';
import 'package:app/pages/face_thumbs_page.dart';
import 'package:app/widget/nicely_dismissable_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:app/helpers/image_crop.dart';

import 'simple_photo_viewer.dart';
import 'simple_video_player_widget.dart';

class SimpleGallery extends StatefulWidget {
  static bool blackBackground = false;
  final List<AssetBaseModel> assets;
  final int currentIndex;
  final String heroVariation;
  final bool reverse;
  final PageController _pageController;
  SimpleGallery({Key? key, required this.assets, required this.currentIndex, required this.heroVariation, this.reverse = false})
      : _pageController = PageController(initialPage: currentIndex),
        super(key: key);

  void show(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (ctx, anim1, anim2) => this,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (ctx, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
    ));
  }

  @override
  State<SimpleGallery> createState() => _SimpleGalleryState();
}

class _SimpleGalleryState extends State<SimpleGallery> {
  bool initialScale = true;
  final panelController = PanelController();
  var panelState = PanelState.CLOSED;
  bool showContextButtons = false;

  Widget buildDragIcon() => Container(
        width: 52,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
      );

  void openMapLink(currentAsset) async {
    final googleUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=${currentAsset.gpsLat},${currentAsset.gpsLong}");
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      Toast.show(msg: "Could not open the map.");
    }
  }

  Future<List<Widget>?> _getFaces(AssetBaseModel asset) async {
    if (asset is! AssetModel) {
      return null;
    }
    var faces = await asset.getFaces();
    var result = <Widget>[];
    for (var face in faces!) {
      result.add(GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => FaceThumbsPage(faceModel: face)));
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 7),
          child: Column(
            children: [
              FaceCropperWidget(faceRect: face.rect, asset: face.asset, width: 50, height: 50, shape: BoxShape.circle),
              Text(face.personName, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey)),
            ],
          ),
        ),
      ));
    }
    return result;
  }

  Widget buildMap(AssetBaseModel asset) {
    TileLayer tileLayer;
    if (asset is AssetModel && asset.account.gaodeMapsEnabled) {
      tileLayer = TileLayer(
        urlTemplate: "${asset.account.getGaodeMapsProxyURL()}?subdomain={s}&x={x}&y={y}&z={z}&lang=zh_cn&size=1&scale=1&style=7",
        subdomains: ['1', '2', '3', '4'],
        userAgentPackageName: 'me.circled.app',
        additionalOptions: {
          'token': asset.account.token,
        },
      );
    } else {
      tileLayer = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'me.circled.app',
      );
    }
    return FlutterMap(
      options: MapOptions(
        initialCenter: latlong2.LatLng(asset.gpsLat!, asset.gpsLong!),
        initialZoom: 16,
        // interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      children: [
        tileLayer,
        CircleLayer(circles: <CircleMarker>[
          CircleMarker(
              point: latlong2.LatLng(asset.gpsLat!, asset.gpsLong!),
              color: Colors.blue.withOpacity(0.7),
              borderStrokeWidth: 2,
              useRadiusInMeter: true,
              radius: 50 // 2000 meters | 2 km
              ),
        ]),
      ],
    );
  }

  Widget _faceBuilder(BuildContext context, AsyncSnapshot<List<Widget>?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text("Error loading faces" + snapshot.error.toString());
    }
    if (!snapshot.hasData) {
      return const SizedBox();
    }
    if (snapshot.data!.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const SizedBox(height: 10),
          ...snapshot.data!,
        ],
      ),
    );
  }

  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
        physics: initialScale ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
        reverse: widget.reverse,
        controller: widget._pageController,
        itemCount: widget.assets.length,
        itemBuilder: (context, index) {
          late Widget detail;
          switch (widget.assets[index].type) {
            case AssetBaseModel.typeImage:
              detail = SimplePhotoViewer(
                  asset: widget.assets[index],
                  heroVariation: widget.heroVariation,
                  observer: (initialSize) {
                    setState(() {
                      initialScale = initialSize;
                    });
                  });
              break;
            case AssetBaseModel.typeVideo:
              detail = SimpleVideoPlayer(
                asset: widget.assets[index],
                heroVariation: widget.heroVariation,
              );
              break;
            default:
              detail = const Icon(Icons.file_copy_outlined, color: Colors.grey, size: 20);
              break;
          }
          final currentAsset = widget.assets[index];
          return SlidingUpPanel(
            defaultPanelState: panelState,
            minHeight: 0,
            maxHeight: 2 * MediaQuery.of(context).size.height / 3,
            controller: panelController,
            onPanelOpened: () => panelState = PanelState.OPEN,
            onPanelClosed: () => panelState = PanelState.CLOSED,
            color: Colors.transparent,
            panel: Column(
              children: [
                AssetActions.draw(AssetActions(
                    assets: [currentAsset],
                    selected: {0},
                    callback: () => setState(() {
                          print("callback2");
                        })).get()),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SizedBox(height: 5, width: MediaQuery.of(context).size.width),
                        buildDragIcon(),
                        const SizedBox(height: 15),
                        Text(currentAsset.name + ", " + currentAsset.readableSize(),
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Text(currentAsset.createdDate, style: Theme.of(context).textTheme.titleSmall),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FutureBuilder(future: _getFaces(currentAsset), builder: _faceBuilder),
                            ],
                          ),
                        ),
                        if (currentAsset.location != null && currentAsset.gpsLat != null && currentAsset.gpsLong != null)
                          TextButton(
                            onPressed: () => openMapLink(currentAsset),
                            child: Text(currentAsset.location!,
                                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.blue)),
                          ),
                        if (currentAsset.gpsLat != null && currentAsset.gpsLong != null) Expanded(child: buildMap(currentAsset)),
                      ],
                    ),
                  ),
                )
              ],
            ),
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            body: NicelyDismissibleWidget(
              heroTag: widget.assets[index].getHeroTag(widget.heroVariation),
              child: detail,
              tapObserver: () => setState(() {
                if (panelController.isPanelOpen) {
                  panelController.close();
                } else if (panelController.isPanelClosed) {
                  panelController.open();
                }
              }),
              dragObserver: (dragUp) {
                if (dragUp) {
                  setState(() {
                    panelController.open();
                    showContextButtons = true;
                  });
                  return true;
                } else if (!panelController.isPanelClosed) {
                  setState(() {
                    panelController.close();
                    showContextButtons = false;
                  });
                  return true;
                }
                return false;
              },
            ),
          );
        });
  }
}
