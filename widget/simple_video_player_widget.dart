import 'package:app/models/asset_base_model.dart';
import 'package:app/widget/cached_thumb_widget.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class SimpleVideoPlayer extends StatefulWidget {
  final AssetBaseModel asset;
  final String heroVariation;
  const SimpleVideoPlayer({Key? key, required this.asset, required this.heroVariation}) : super(key: key);

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  late VideoPlayerController videoPlayerController;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Init video player
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.asset.uri), httpHeaders: widget.asset.requestHeaders);
      await videoPlayerController.initialize();
      // Init video controls
      chewieController = ChewieController(
        allowFullScreen: true,
        showOptions: true,
        showControlsOnInitialize: false,
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        autoInitialize: false,
        // customControls: Container(),
        // showControls: false,
        // useRootNavigator: false,
      );
      // Initially muted
      await videoPlayerController.setVolume(0);
      // Force rebuild
      setState(() {});
    } catch (e) {
      print("error initializing video player: "+e.toString());
    }
  }

  @override
  void dispose() {
    videoPlayerController.pause();
    videoPlayerController.dispose();
    chewieController?.dispose();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return chewieController != null && chewieController!.videoPlayerController.value.isInitialized
      ? Material(
          child: Chewie(controller: chewieController!))
      : SizedBox(width: double.infinity, height: double.infinity,
          child: CachedThumb(asset: widget.asset, fit: false));
  }
}
