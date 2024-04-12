import 'dart:ui';

import 'package:app/app_consts.dart';
import 'package:flutter/material.dart';

class RoundInputHint extends StatelessWidget {
  final TextEditingController ctrl;
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboard;
  final bool autoFocus;
  final bool disabled;
  final bool compulsory;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? inputAction;

  const RoundInputHint({
    required this.ctrl,
    required this.hintText,
    this.icon,
    this.isPassword=false,
    this.keyboard=TextInputType.text,
    this.inputAction=TextInputAction.next,
    this.autoFocus=false,
    this.disabled=false,
    this.compulsory=false,
    this.onSubmitted,
    this.onChanged,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FocusNode myFocusNode = FocusNode();
    return SizedBox(
      height: 50,
      child: TextField(
        //style: const TextStyle(background: ),
        // enabled: !disabled,
        textInputAction: inputAction,
        focusNode: myFocusNode,
        onSubmitted: onSubmitted==null ? null : (value) {
          onSubmitted!(value);
          myFocusNode.requestFocus();
        },
        onChanged: onChanged,
        keyboardType: keyboard,
        readOnly: disabled,
        enabled: !disabled,
        autofocus: autoFocus,
        controller: ctrl,
        enableSuggestions: false,
        autocorrect: false,
        obscureText: isPassword,
        maxLines: 1,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          labelText: hintText,
          labelStyle: TextStyle(color: compulsory ? AppConst.attentionColor.withOpacity(0.5) : Colors.grey.withOpacity(0.8)),
          prefixIcon: icon!=null ? Icon(icon, color: AppConst.iconColor, size: 25) : null,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConst.borderRadius),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.8),
              )
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConst.borderRadius),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
              )
          ),
        ),
      ),
    );
  }
}