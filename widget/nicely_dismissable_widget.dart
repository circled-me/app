import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class InnerViewScaleStateNotification extends Notification {
  final bool initialState;
  const InnerViewScaleStateNotification({required this.initialState});
}

class NicelyDismissibleWidget extends StatefulWidget {
  final Widget child;
  final String heroTag;
  final bool Function(bool)? dragObserver;
  final Function()? tapObserver;
  const NicelyDismissibleWidget({Key? key, required this.child, required this.heroTag, this.dragObserver, this.tapObserver}) : super(key: key);

  @override
  State<NicelyDismissibleWidget> createState() => _NicelyDismissibleWidgetState();
}

class _NicelyDismissibleWidgetState extends State<NicelyDismissibleWidget> {
  Offset beginningDragPosition = Offset.zero;
  Offset currentDragPosition = Offset.zero;
  bool isInitialScaleState = true;
  bool isDismissing = false;
  int photoViewAnimationDurationMilliSec = 0;

  double get photoViewScale {
    return max(1.0 - currentDragPosition.distance * 0.001, 0.5);
  }

  double get photoViewOpacity {
    return max(1.0 - currentDragPosition.distance * 0.005, 0.1);
  }

  Matrix4 get photoViewTransform {
    final translationTransform = Matrix4.translationValues(
      currentDragPosition.dx,
      currentDragPosition.dy,
      0.0,
    );

    final scaleTransform = Matrix4.diagonal3Values(
      photoViewScale,
      photoViewScale,
      1.0,
    );

    return translationTransform * scaleTransform;
  }

  void onVerticalDragStart(DragStartDetails details) {
    setState(() {
      photoViewAnimationDurationMilliSec = 0;
    });
    beginningDragPosition = details.globalPosition;
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    if (!isDismissing && widget.dragObserver != null) {
      if (widget.dragObserver!(details.delta.dy < 0)) {
        return;
      } else {
        isDismissing = true;
      }
    }
    setState(() {
      currentDragPosition = Offset(
        details.globalPosition.dx - beginningDragPosition.dx,
        details.globalPosition.dy - beginningDragPosition.dy,
      );
    });
  }

  void onVerticalDragEnd(DragEndDetails details) {
    isDismissing = false;
    if (currentDragPosition.distance < 100.0) {
      setState(() {
        photoViewAnimationDurationMilliSec = 200;
        currentDragPosition = Offset.zero;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<InnerViewScaleStateNotification>(
      onNotification: (notification) {
        setState(() {
          isInitialScaleState = notification.initialState;
        });
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white.withOpacity(photoViewOpacity),
        body: GestureDetector(
          onTap: () => widget.tapObserver!=null ? widget.tapObserver!() : null,
          onVerticalDragStart: isInitialScaleState ? onVerticalDragStart : null,
          onVerticalDragUpdate: isInitialScaleState ? onVerticalDragUpdate : null,
          onVerticalDragEnd: isInitialScaleState ? onVerticalDragEnd : null,
          child: AnimatedContainer(
            duration: Duration(milliseconds: photoViewAnimationDurationMilliSec),
            transform: photoViewTransform,
            child: Center(
              child: Hero(
                tag: widget.heroTag,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
