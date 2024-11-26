import 'package:app/app_consts.dart';
import 'package:app/helpers/user.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:app/helpers/toast.dart';

import '../main.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, this.server="", this.token="", this.closable=false}) : super(key: key);

  final String server, token;
  final bool closable;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  static const normalLogin = 0;
  static const newServer = 1;
  static const invitation = 2;
  int loginType = normalLogin;
  bool invited = false;
  final loginTextTitles = ["Sign in to your server", "Create Admin user", "Invited? Create your own user"];
  final altButtonTitles = ["Or just normal Login", "Or create first user?", "Got invitation?"];

  late AnimationController _controller;
  TextEditingController serverAddrCtrl = TextEditingController(text: "https://.circled.me");
  TextEditingController emailAddrCtrl = TextEditingController();
  TextEditingController tokenCtrl = TextEditingController();
  TextEditingController passwordCtrl = TextEditingController();
  TextEditingController passwordConfirmCtrl = TextEditingController();

  void _doLogin() async {
    if (emailAddrCtrl.text == "") {
      Toast.show(msg: "Please enter username");
      return;
    }
    if (passwordCtrl.text == "") {
      Toast.show(msg: "Please enter password");
      return;
    }
    if (loginType > normalLogin) {
      if (passwordCtrl.text.length < 8) {
        Toast.show(msg: "Please select password with at least 8 characters");
        return;
      }
      if (passwordCtrl.text != passwordConfirmCtrl.text) {
        Toast.show(msg: "Please confirm password");
        return;
      }
    }
    final rootContext = MyApp.navigatorKey.currentState!.context;
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              //mainAxisSize: MainAxisSize.max,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Logging in..."),
              ],
            ),
          ),
        );
      },
    );
    try {
      final error = await User.login(
        serverAddrCtrl.text,
        loginType == invitation ? tokenCtrl.text : "",
        emailAddrCtrl.text,
        passwordCtrl.text,
        loginType == newServer,
      );
      if (error != "") {
        Toast.show(msg: error);
        return;
      }
      Navigator.pop(context); // pop the login page on success
    } on Exception catch (e) {
      Toast.show(msg: e.toString());
    } finally {
      Navigator.pop(rootContext); // pop the loading dialog
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    serverAddrCtrl.text = widget.server;
    tokenCtrl.text = widget.token;
    if (widget.server != "" && widget.token != "") {
      loginType = invitation;
      invited = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    serverAddrCtrl.dispose();
    emailAddrCtrl.dispose();
    passwordCtrl.dispose();
    passwordConfirmCtrl.dispose();
    tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar:   AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 0,
      ),
      //resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        //physics: const NeverScrollableScrollPhysics(),
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: w,
              height: h*0.1,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("img/strip_hero2.png"),
                  fit: BoxFit.fill,
                )
              ),
              child: widget.closable
                ? Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 35)
                    ),
                )
                : null,
            ),
            Container(
              width: w,
              margin: const EdgeInsets.only(left: 20, right: 20),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hello", style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 10),
                  Text(loginTextTitles[loginType], style: const TextStyle(fontSize: 20,color: Colors.grey)),
                  const SizedBox(height: 20),
                  RoundInputHint(ctrl: serverAddrCtrl, hintText: "Server", icon: Icons.device_hub, disabled: invited, keyboard: TextInputType.url,),
                  if (loginType==invitation && !invited) const SizedBox(height: 15),
                  if (loginType==invitation && !invited) RoundInputHint(ctrl: tokenCtrl, hintText: "Token", icon: Icons.generating_tokens, disabled: invited),
                  const SizedBox(height: 15),
                  RoundInputHint(ctrl: emailAddrCtrl, hintText: "Username", icon: Icons.account_circle, keyboard: TextInputType.name,),
                  const SizedBox(height: 15),
                  RoundInputHint(
                    ctrl: passwordCtrl,
                    hintText: "Password",
                    isPassword: true,
                    icon: Icons.password_outlined,
                    keyboard: TextInputType.visiblePassword,
                    inputAction: TextInputAction.go,
                    onSubmitted: (_) => _doLogin(),
                  ),
                  Visibility(
                    visible: loginType > normalLogin,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        RoundInputHint(ctrl: passwordConfirmCtrl, hintText: "Confirm Password", isPassword: true, icon: Icons.password_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConst.borderRadius))),
                      onPressed: _doLogin,
                      child: Text(loginType > normalLogin ? "Create User" : "Login", style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => setState(() {
                        loginType = (loginType+1)%3;
                        invited = false; // clear it
                      }),
                      child: Text(altButtonTitles[(loginType+1)%3], style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => setState(() {
                        loginType = (loginType+2)%3;
                        invited = false; // clear it
                      }),
                      child: Text(altButtonTitles[(loginType+2)%3], style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              )
            ),
            const SizedBox(height: 30),
          ],
        ),
      )
    );
  }
}
