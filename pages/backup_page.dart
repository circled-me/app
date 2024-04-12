import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({Key? key}) : super(key: key);

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          toolbarHeight: 0,
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 30,),
              ElevatedButton(
                onPressed: () => Provider.of<BackupService>(context, listen: false).start(),
                child: const Text("Backup"),
              )
            ],
          )
        )
    );
  }
}
