import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  // 🔐 32-byte key (AES-256)
  // In real deployment → store securely / env / keystore
  static final _key = Key.fromUtf8('12345678901234567890123456789012');

  // 🔐 16-byte IV
  static final _iv = IV.fromLength(16);

  static final _encrypter = Encrypter(AES(_key, mode: AESMode.gcm));

  /// Encrypt Map → Base64 String
  static String encryptMap(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final encrypted = _encrypter.encrypt(jsonString, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt Base64 String → Map
  static Map<String, dynamic> decryptMap(String encryptedBase64) {
    final decrypted =
    _encrypter.decrypt64(encryptedBase64, iv: _iv);
    return jsonDecode(decrypted);
  }
}
