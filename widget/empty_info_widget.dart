import 'package:flutter/material.dart';

class EmptyInfoWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyInfoWidget(this.icon, this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 50),
          Text(text,
            style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 17),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
