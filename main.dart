import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:app/models/album_model.dart';
import 'package:app/pages/album_thumbs_page.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/services/assets_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/services/uni_link_service.dart';
import 'package:app/widget/webview_dialog_widget.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proximity_screen_lock_ios/proximity_screen_lock_ios.dart';
import 'package:provider/provider.dart';
// import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:push/push.dart';
import 'package:uni_links/uni_links.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'app_consts.dart';
import 'pages/tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/accounts_service.dart';
import 'services/groups_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

bool _initialUriIsHandled = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //   statusBarColor: Colors.white.withOpacity(0.5), // transparent status bar
  //   systemStatusBarContrastEnforced: true,
  // ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final proximityIOS = ProximityScreenLockIos();
  static String version = "";
  static int numUnread = 0;

  @override
  State<MyApp> createState() => _MyAppState();

  static void openVideoCallView(String url) async {
    await Permission.camera.request();
    await Permission.microphone.request();

    // Try finding the corresponding account for this url
    String queryString = "";
    final accounts = AccountsService.getAccounts.where((account) => url.startsWith("${account.server}/"));
    if (accounts.isNotEmpty) {
      queryString = "?token=${accounts.first.token}";
      print("Found account for call: ${accounts.first.server}, query: $queryString");
    } else {
      print("No account found for call");
    }
    final rootContext = MyApp.navigatorKey.currentState!.context;
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) => request.grant(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print("WebView is loading (progress : $progress%)");
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onHttpError: (HttpResponseError error) {
            print('HTTP error: $error');
          },
          onWebResourceError: (WebResourceError error) {
            print('Web Resource error: $error');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation Request: $request');
            return NavigationDecision.navigate;
          },
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      // AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    controller.clearCache();
    // Finally, load the URL
    url = "$url$queryString#inapp";
    controller.loadRequest(Uri.parse(url));

    // if (Platform.isAndroid) {
    //   await ProximitySensor.setProximityScreenOff(true).onError((error,
    //       stackTrace) {
    //     print("Could not enable screen off functionality");
    //     Toast.show(msg: "Could not enable screen off functionality");
    //     return null;
    //   });
    // } else
    if (Platform.isIOS && await proximityIOS.isProximityLockSupported()) {
      await proximityIOS.setActive(true);
      // TODO: Or just use Swift and always enable it?
      //     UIDevice.current.isProximityMonitoringEnabled = true
    }
    await showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WebViewDialog(controller: controller);
      },
    );
    // if (Platform.isAndroid) {
    //   await ProximitySensor.setProximityScreenOff(false);
    // } else
    if (Platform.isIOS && await proximityIOS.isProximityLockSupported()) {
      await proximityIOS.setActive(false);
    }
  }

}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Object? _err;
  StreamSubscription? _uriSub;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('AppLifecycleState: $state');
    if (state == AppLifecycleState.resumed) {
      for (var account in AccountsService.getAccounts) {
        account.updatePushServer();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppVersion();
    _handleIncomingLinks();
    _handleInitialUri();
    _handlePushNotifications();
    _initGroupUpdates();
  }

  @override
  void dispose() {
    _uriSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initGroupUpdates() {
    //GroupsService.instance
  }

  void _loadAppVersion() {
    PackageInfo.fromPlatform().then((packageInfo) {
      MyApp.version = packageInfo.version;
    });
  }
  void _showAlbum(AlbumModel? album, bool ask, RemoteMessage? remoteMessage) {
    if (album == null) {
      print("no album :(");
      return;
    }
    final rootContext = MyApp.navigatorKey.currentState!.context;
    void show() {
      Navigator.of(rootContext).push(MaterialPageRoute(
          builder: (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                toolbarHeight: 0,
              ),
              body: AlbumThumbsPage(albumInfo: album)
          )
        )
      );
    }
    if (!ask || remoteMessage == null || remoteMessage.notification == null) {
      show();
      return;
    }
    showDialog<bool>(
      context: rootContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(remoteMessage.notification!.title!),
        content: Text(remoteMessage.notification!.body!),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ignore'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open'),
          ),
        ],
      ),
    ).then((yes) {
      if (yes!=null && yes) {
        show();
      }
    });
  }

  void _handleIncomingCall(Map<Object?, Object?>? data) {
    final params = CallKitParams(
      id: data!["id"] as String,
      handle: data["caller_id"] as String,
      nameCaller: data["caller_name"] as String,
      appName: "circled.me"
    );
    FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  void _handlePushNotification(bool tapped, Map<Object?, Object?>? data, RemoteMessage? remoteMessage) {
    if (data == null) {
      return;
    }
    if (data["caller_id"] is String && data["caller_id"] != "") {
      _handleIncomingCall(data);
      return;
    }
    final ask = remoteMessage!=null
        && remoteMessage.notification != null
        && remoteMessage.notification!.title!=null
        && remoteMessage.notification!.title!=null;

    final token = data["token"] as String;
    if (data["type"] == "album") {
      AlbumsService.onReady(() {
        final albumId = int.parse(data["album"] as String);

        final album = AlbumsService.getAlbum(albumId, accountPushToken: token);
        if (album == null) {
          // Could be a new shared album, try reloading
          final accs = AccountsService.getAccounts.where((account) => account.pushToken == data["token"]);
          if (accs.isEmpty) {
            print("Cannot find account for push token");
            return;
          }
          AlbumsService.reloadAccount(accs.first).then((_) {
            final album = AlbumsService.getAlbum(albumId, accountPushToken: token);
            _showAlbum(album, ask, remoteMessage);
            AlbumsService.instance.notifyListeners(); // Refresh albums page
          });
        }
       _showAlbum(album, ask, remoteMessage);
      });
    } else if (tapped && data["type"] is String && (data["type"] as String).startsWith("group_")) {
      final groupID = data["group"] as String;
      UniLinksService.add(Uri.parse("https://dummy/group/$token/$groupID"));
    }
  }


  void _handlePushNotifications() {
    print("Setting up push notifications");
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) {
        print("CallEvent: null");
        return;
      }
      print("CallEvent: $event");
      if (event.event == Event.actionCallAccept || event.event == Event.actionCallStart) {
        FlutterCallkitIncoming.activeCalls().then((calls) {
          Timer(Duration(seconds: 1), () {
            FlutterCallkitIncoming.endAllCalls().then((calls) {
              String callUrl = "";
              // In iOS, the handle is the caller's ID
              if (event.body["handle"] is String && event.body["handle"] != "") {
                callUrl = event.body["handle"];
              // In Android, the number is the caller's ID
              } else if (event.body["number"] is String && event.body["number"] != "") {
                callUrl = event.body["number"];
              } else {
                print("ERROR: No handle or number in call event: ${jsonEncode(event)}");
                return;
              }
              MyApp.openVideoCallView(callUrl);
            });
          });
        });
      }
      if (event.event == Event.actionCallEnded) {
        FlutterCallkitIncoming.endAllCalls();
      }
    });

    // TODO: Handle badges
    Push.instance.requestPermission().then(AccountsService.pushTokenReceived);

    // Handle notification launching app from terminated state
    Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
      if (data == null) {
        print("App was not launched by tapping a notification");
        return;
      } else {
        print('Notification tap launched app from terminated state:\nRemoteMessage: ${data} \n');
      }
      _handlePushNotification(true, Platform.isAndroid ? data : data["data"] as Map<Object?, Object?>?, null);
    });

    // Handle notification taps
    Push.instance.onNotificationTap.listen((data) {
      print('Notification was tapped:\nData: ${data} \n');
      _handlePushNotification(true, Platform.isAndroid ? data : data["data"] as Map<Object?, Object?>?, null);
    });

    // Handle push notifications
    Push.instance.onMessage.listen((message) {
      print('RemoteMessage received while app is in foreground:\n'
          'RemoteMessage.Notification: ${message.notification} \n'
          ' title: ${message.notification?.title.toString()}\n'
          ' body: ${message.notification?.body.toString()}\n'
          'RemoteMessage.onMessage: ${message.data}');

      if (message.data == null) {
        return;
      }
      _handlePushNotification(false, Platform.isAndroid ? message.data : message.data!["data"] as Map<Object?, Object?>?, message);
    });

    // Handle push notifications
    Push.instance.onBackgroundMessage.listen((message) {
      print('RemoteMessage received while app is in background:\n'
          'RemoteMessage.Notification: ${message.notification} \n'
          ' title: ${message.notification?.title.toString()}\n'
          ' body: ${message.notification?.body.toString()}\n'
          'RemoteMessage.onBackgroundMessage: ${message.data}');

      if (message.data == null) {
        return;
      }
      _handlePushNotification(false, Platform.isAndroid ? message.data : message.data!["data"] as Map<Object?, Object?>?, null);
    });
  }
  /// Handle incoming links - the ones that the app will receive from the OS
  /// while already started.
  void _handleIncomingLinks() {
    if (!kIsWeb) {
      FlutterCallkitIncoming.requestFullIntentPermission();
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _uriSub = uriLinkStream.listen((Uri? uri) {
        if (!mounted || uri==null) return;
        print('uni_links got uri: $uri');
        setState(() {
          UniLinksService.add(uri);
          _err = null;
        });
      }, onError: (Object err) {
        if (!mounted) return;
        print('uni_links got err: $err');
        setState(() {
          if (err is FormatException) {
            _err = err;
          } else {
            _err = null;
          }
        });
      });
    }
  }

  /// Handle the initial Uri - the one the app was started with
  ///
  /// **ATTENTION**: `getInitialLink`/`getInitialUri` should be handled
  /// ONLY ONCE in your app's lifetime, since it is not meant to change
  /// throughout your app's life.
  ///
  /// We handle all exceptions, since it is called from initState.
  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      print('uni_links _handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          print('uni_links no initial uri');
        } else {
          print('uni_links got initial uri: $uri');
        }
        if (!mounted || uri==null) return;
        setState(() => UniLinksService.add(uri));
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        print('failed to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        print('malformed initial uri');
        setState(() => _err = err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Load chain: Accounts -> Groups -> WebSockets
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsService.instance,),
        ChangeNotifierProxyProvider<AccountsService, GroupsService>(
          create: (_) => GroupsService.instance,
          update: (_, accounts, __) => GroupsService.instance..reloadAccounts(accounts),
          lazy: false,
        ),
        ChangeNotifierProxyProvider<AccountsService, AlbumsService>(
          create: (_) => AlbumsService.instance,
          update: (_, accounts, __) => AlbumsService.instance..reloadAccounts(accounts, true),
        ),
        ChangeNotifierProxyProvider<AccountsService, AssetsService>(
          create: (_) => AssetsService.instance,
          update: (_, accounts, __) => AssetsService.instance..reloadAccounts(accounts),
        ),
        ChangeNotifierProxyProvider<GroupsService, WebSocketService>(
          create: (_) => WebSocketService.instance,
          update: (_, __, ___) => WebSocketService.instance..reloadAccounts(AccountsService.instance),
          lazy: false,
        ),
        // ChangeNotifierProvider(create: (ctx) => MomentsService.instance,),
      ],
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: AppConst.mainColor,
          useMaterial3: false,
        ),
        home: const TabsPage()
      ),
    );
  }
}
