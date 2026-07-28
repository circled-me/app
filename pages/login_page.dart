import 'package:app/app_consts.dart';
import 'package:app/helpers/user.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:app/helpers/toast.dart';
import 'package:app/widget/settings_ui.dart';

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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 16),
                Expanded(child: Text("Logging in...")),
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: w,
              height: h * 0.1,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("img/strip_hero2.png"),
                  fit: BoxFit.fill,
                ),
              ),
              child: widget.closable
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Material(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.close, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SettingsStyles.pagePadding,
                8,
                SettingsStyles.pagePadding,
                SettingsStyles.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hello",
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loginTextTitles[loginType],
                    style: SettingsStyles.itemSubtitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  SettingsCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoundInputHint(
                          ctrl: serverAddrCtrl,
                          hintText: "Server",
                          icon: Icons.device_hub,
                          disabled: invited,
                          keyboard: TextInputType.url,
                        ),
                        if (loginType == invitation && !invited) ...[
                          const SizedBox(height: SettingsStyles.itemGap),
                          RoundInputHint(
                            ctrl: tokenCtrl,
                            hintText: "Token",
                            icon: Icons.generating_tokens,
                            disabled: invited,
                          ),
                        ],
                        const SizedBox(height: SettingsStyles.itemGap),
                        RoundInputHint(
                          ctrl: emailAddrCtrl,
                          hintText: "Username",
                          icon: Icons.account_circle,
                          keyboard: TextInputType.name,
                        ),
                        const SizedBox(height: SettingsStyles.itemGap),
                        RoundInputHint(
                          ctrl: passwordCtrl,
                          hintText: "Password",
                          isPassword: true,
                          icon: Icons.password_outlined,
                          keyboard: TextInputType.visiblePassword,
                          inputAction: TextInputAction.go,
                          onSubmitted: (_) => _doLogin(),
                        ),
                        if (loginType > normalLogin) ...[
                          const SizedBox(height: SettingsStyles.itemGap),
                          RoundInputHint(
                            ctrl: passwordConfirmCtrl,
                            hintText: "Confirm Password",
                            isPassword: true,
                            icon: Icons.password_outlined,
                          ),
                        ],
                        const SizedBox(height: 18),
                        SettingsPrimaryButton(
                          label: loginType > normalLogin ? "Create User" : "Login",
                          expanded: true,
                          icon: loginType > normalLogin ? Icons.person_add_alt_1 : Icons.login,
                          onPressed: _doLogin,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsSecondaryButton(
                    label: altButtonTitles[(loginType + 1) % 3],
                    expanded: true,
                    onPressed: () => setState(() {
                      loginType = (loginType + 1) % 3;
                      invited = false;
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppConst.mainColor,
                        minimumSize: const Size(0, SettingsStyles.buttonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConst.borderRadius),
                        ),
                      ),
                      onPressed: () => setState(() {
                        loginType = (loginType + 2) % 3;
                        invited = false;
                      }),
                      child: Text(altButtonTitles[(loginType + 2) % 3]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
