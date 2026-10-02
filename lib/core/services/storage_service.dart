import 'package:flutter/services.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const MethodChannel _channel =
      MethodChannel('mas_ai/storage');

  Future<bool> isStorageConfigured() async {
    final result = await _channel.invokeMethod<bool>(
      'isStorageConfigured',
    );

    return result ?? false;
  }

  Future<bool> chooseStorageFolder() async {
    final result = await _channel.invokeMethod<bool>(
      'chooseStorageFolder',
    );

    return result ?? false;
  }

  Future<String?> getStorageUri() async {
    return _channel.invokeMethod<String>(
      'getStorageUri',
    );
  }
}
