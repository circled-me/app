

import 'package:fluttertoast/fluttertoast.dart';

class Toast {
  static const ToastGravityCenter = ToastGravity.CENTER;
  static void show({String msg="", int timeInSecForIosWeb=2, ToastGravity gravity=ToastGravity.TOP}) {
    Fluttertoast.showToast(msg: msg, timeInSecForIosWeb: timeInSecForIosWeb, gravity: gravity);
  }
}