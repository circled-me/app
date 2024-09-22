
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/custom_cache.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../models/asset_model.dart';

class ImageUtils {
  static Future<ui.Image> getUiImage(AssetModel asset) async {
    Completer<ImageInfo> completer = Completer();
    ImageProvider? img = CachedNetworkImageProvider(
        asset.bigThumbUrl,
        cacheManager: CustomCacheManager.instance,
        headers: asset.requestHeaders
    );
    img
        ?.resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }));
    ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }
}

class FaceImagePainter extends CustomPainter {
  ui.Image resImage;
  Rect rectCrop;
  FaceImagePainter(this.resImage, this.rectCrop);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Size imageSize =
    Size(resImage.width.toDouble(), resImage.height.toDouble());
    FittedSizes sizes = applyBoxFit(BoxFit.cover, imageSize, size);

    Rect inputSubRect = rectCrop;
    final Rect outputSubRect =
    Alignment.center.inscribe(sizes.destination, rect);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;
    canvas.drawRect(rect, paint);

    canvas.drawImageRect(resImage, inputSubRect, outputSubRect, Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}


class FaceCropperWidget extends StatelessWidget {
  final AssetModel asset;
  final Rect faceRect;
  final double? width;
  final double? height;
  final BoxShape? shape;
  const FaceCropperWidget({
    Key? key,
    required this.asset,
    required this.faceRect,
    this.width,
    this.height,
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape ?? BoxShape.rectangle,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: FutureBuilder(
        future: ImageUtils.getUiImage(asset),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null && snapshot.data! is ui.Image) {
            // If the Future is complete, display the preview.
            return paintImage(snapshot.data! as ui.Image);
          } else {
            // Otherwise, display a loading indicator.
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Widget paintImage(ui.Image image) {
    return CustomPaint(
      painter: FaceImagePainter(
        image,
        faceRect,
      ),
      child: SizedBox(
        width: faceRect.width,
        height: faceRect.height,
      ),
    );
  }
}
