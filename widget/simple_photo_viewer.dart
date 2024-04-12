import 'dart:convert';

import 'package:app/models/asset_base_model.dart';
import 'package:app/widget/cached_thumb_widget.dart';
import 'package:app/widget/nicely_dismissable_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class SimplePhotoViewer extends StatefulWidget {
  final AssetBaseModel asset;
  final String heroVariation;
  final bool disableGestures;
  final Function(bool)? observer;
  const SimplePhotoViewer({Key? key, required this.asset, required this.heroVariation, this.observer, this.disableGestures=false}) : super(key: key);

  @override
  State<SimplePhotoViewer> createState() => _SimplePhotoViewerState();
}

class _SimplePhotoViewerState extends State<SimplePhotoViewer> {
  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(widget.asset.bigThumbUrl, headers: widget.asset.requestHeaders),
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained*4,
      disableGestures: widget.disableGestures,
      scaleStateChangedCallback: (state) {
        setState(() {
          InnerViewScaleStateNotification(initialState: state == PhotoViewScaleState.initial).dispatch(context);
          if (widget.observer != null) {
            widget.observer!(state == PhotoViewScaleState.initial);
          }
        });
      },
      tightMode: true,
      loadingBuilder: (ctx, event) => SizedBox(width: double.infinity, height: double.infinity,
          child: CachedThumb(asset: widget.asset, fit: false)
      ),
    );
  }
}
