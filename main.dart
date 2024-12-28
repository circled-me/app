import 'dart:async';
import 'dart:io' show Platform;

import 'package:app/models/album_model.dart';
import 'package:app/pages/album_thumbs_page.dart';
import 'package:app/services/albums_service.dart';
import 'package:app/services/assets_service.dart';
import 'package:app/services/websocket_service.dart';
import 'package:app/services/uni_link_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:push/push.dart';
import 'package:uni_links/uni_links.dart';
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
  static String version = "";
  static int numUnread = 0;

  @override
  State<MyApp> createState() => _MyAppState();
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
        title: Text(remoteMessage!.notification!.title!),
        content: Text(remoteMessage!.notification!.body!),
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
      if (yes!=null && yes!) {
        show();
      }
    });
  }

  void _handlePushNotification(Map<Object?, Object?>? data, RemoteMessage? remoteMessage) {
    if (data == null) {
      return;
    }
    final ask = remoteMessage!=null
        && remoteMessage!.notification != null
        && remoteMessage!.notification!.title!=null
        && remoteMessage!.notification!.title!=null;

    if (data!["type"] == "album") {
      AlbumsService.onReady(() {
        final token = data!["token"] as String;
        final albumId = int.parse(data!["album"] as String);

        final album = AlbumsService.getAlbum(albumId, accountPushToken: token);
        if (album == null) {
          // Could be a new shared album, try reloading
          final acc = AccountsService.getAccounts.where((account) => account.pushToken == data!["token"]).elementAtOrNull(0);
          if (acc == null) {
            print("Cannot find account for push token");
            return;
          }
          AlbumsService.reloadAccount(acc!).then((_) {
            final album = AlbumsService.getAlbum(albumId, accountPushToken: token);
            _showAlbum(album, ask, remoteMessage);
            AlbumsService.instance.notifyListeners(); // Refresh albums page
          });
        }
       _showAlbum(album, ask, remoteMessage);
      });
    } else if (data!["type"] == "group") {
      UniLinksService.add(Uri.parse("https://dummy/group/"));
    }
  }


  void _handlePushNotifications() {
    // TODO: Handle badges
    Push.instance.requestPermission().then(AccountsService.pushTokenReceived);

    // Handle notification launching app from terminated state
    Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
      if (data == null) {
        print("App was not launched by tapping a notification");
        return;
      } else {
        print('Notification tap launched app from terminated state:\n'
            'RemoteMessage: ${data} \n');
      }
      _handlePushNotification(Platform.isAndroid ? data : data!["data"] as Map<Object?, Object?>?, null);
    });

    // Handle notification taps
    Push.instance.onNotificationTap.listen((data) {
      print('Notification was tapped:\n'
          'Data: ${data} \n');
      if (data == null) {
        return;
      }
      _handlePushNotification(Platform.isAndroid ? data : data!["data"] as Map<Object?, Object?>?, null);
    });

    // Handle push notifications
    Push.instance.onMessage.listen((message) {
      print('RemoteMessage received while app is in foreground:\n'
          'RemoteMessage.Notification: ${message.notification} \n'
          ' title: ${message.notification?.title.toString()}\n'
          ' body: ${message.notification?.body.toString()}\n'
          'RemoteMessage.Data: ${message.data}');

      if (message.data == null) {
        return;
      }
      _handlePushNotification(Platform.isAndroid ? message.data : message.data!["data"] as Map<Object?, Object?>?, message);
    });

    // Handle push notifications
    Push.instance.onBackgroundMessage.listen((message) {
      print('RemoteMessage received while app is in background:\n'
          'RemoteMessage.Notification: ${message.notification} \n'
          ' title: ${message.notification?.title.toString()}\n'
          ' body: ${message.notification?.body.toString()}\n'
          'RemoteMessage.Data: ${message.data}');
      if (message.data == null) {
        return;
      }
      _handlePushNotification(Platform.isAndroid ? message.data : message.data!["data"] as Map<Object?, Object?>?, null);
    });
  }
  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  void _handleIncomingLinks() {
    if (!kIsWeb) {
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
