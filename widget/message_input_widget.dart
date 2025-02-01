import 'dart:ui';

import 'package:app/app_consts.dart';
import 'package:app/helpers/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String? hintText;
  final IconData? icon;
  final TextInputType keyboard;
  final bool autoFocus;
  final bool disabled;
  final double fontSize;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  const MessageInput({
    required this.ctrl,
    required this.hintText,
    this.icon,
    this.keyboard=TextInputType.multiline,
    this.autoFocus=false,
    this.disabled=false,
    this.fontSize=18,
    this.onSubmitted,
    this.onChanged,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
      // TODO: Finish pasting images, etc...
      // contentInsertionConfiguration: ContentInsertionConfiguration(
      //     allowedMimeTypes: <String>[
      //       'image/png',
      //       'image/bmp',
      //       'image/jpg',
      //       'image/tiff',
      //       'image/gif',
      //       'image/jpeg',
      //       'image/webp',
      //       'image/heif',
      //       'image/heic',
      //     ],
      //     onContentInserted: (value) {
      //       print('${value.mimeType}: ${value.uri}');
      //       Toast.show(msg: '${value.mimeType}: ${value.uri}, size:${value.data?.length}');
      //     },
      //   ),
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        keyboardType: keyboard,
        readOnly: disabled,
        enabled: !disabled,
        autofocus: autoFocus,
        controller: ctrl,
        style: TextStyle(
          fontSize: fontSize,
        ),
        enableSuggestions: true,
        autocorrect: true,
        textCapitalization: TextCapitalization.sentences,
        minLines: 1,
        maxLines: 7,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          labelStyle: TextStyle(
            color: Colors.grey,
            fontSize: fontSize,
          ),
          label: hintText == null ? null : Row(
            children: [
              const SizedBox(width: 5),
              const SizedBox(width: 10, height: 10, child: Center(child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2.5))),
              const SizedBox(width: 10),
              Text(hintText!),
            ]
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.1),
              )
          ),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.1),
              )
          ),
          // enabledBorder: OutlineInputBorder(
          //     // borderRadius: BorderRadius.circular(AppConst.borderRadius),
          //     borderSide: BorderSide(
          //       color: Colors.grey.withOpacity(0.3),
          //     )
          // ),
        ),
      ),
    );
  }
}