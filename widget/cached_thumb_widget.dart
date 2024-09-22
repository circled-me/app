import 'package:app/models/asset_base_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../app_consts.dart';
import '../custom_cache.dart';

class CachedThumb extends StatelessWidget {
  static const small = 0;
  static const big = 1;
  final AssetBaseModel asset;
  final bool fit, selected;
  final int size;
  final cropX1, cropY1, cropX2, cropY2;
  const CachedThumb({Key? key, required this.asset, this.fit=true, this.selected=false, this.size=small, this.cropX1=-1, this.cropY1=-1, this.cropX2=-1, this.cropY2=-1}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CachedNetworkImage(
        cacheManager: CustomCacheManager.instance,
        imageUrl: size == small ? asset.thumbUrl : asset.albumThumbUrl,
        errorWidget: (context, url, error) => const Icon(Icons.question_mark, size: 50, color: Colors.grey),
        httpHeaders: asset.requestHeaders,
        fit: fit? BoxFit.cover : BoxFit.contain,
      ),
      decoration: selected
          ? BoxDecoration(border: Border.all(color: AppConst.mainColor, width: 4))
          : null,
    );
  }
}
