import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Simple wrapper class for secure storage
class Storage {
  static const storage = FlutterSecureStorage();

  final String name;
  const Storage(this.name);

  Future<String?> read() async {
    try {
      return storage.read(key: name);
    } catch (e) {
      return "";
    }
  }

  Future<void> write(String content) async {
    return storage.write(key: name, value: content);
  }

  Future<void> delete() async {
    return storage.delete(key: name);
  }
}