import 'package:flutter/material.dart';

class UniLinksService extends ChangeNotifier {

  final List<Uri> _waitingUris = [];
  final List<Function> _subscribers = [];

  static UniLinksService instance = UniLinksService();

  static bool subscribe(Function f) {
    final result = instance._trySubscriber(f);
    instance._subscribers.add(f);
    return result;
  }

  static void add(Uri uri) {
    print("new uri added: "+uri.toString());
    instance._waitingUris.add(uri);
    for (var f in instance._subscribers) {
      if (instance._trySubscriber(f)) {
        break;
      }
    }
  }

  bool _trySubscriber(Function f) {
    final size = _waitingUris.length;
    _waitingUris.removeWhere((uri) => f(uri));
    return size != _waitingUris.length;
  }
}