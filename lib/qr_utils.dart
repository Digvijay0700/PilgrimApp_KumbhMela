import 'dart:convert';
import 'package:crypto/crypto.dart';

const String QR_SECRET = "KUMBHATHON_2027_SECRET";

String generateSignature(Map<String, dynamic> payload) {
  final data = "${payload['kid']}|${payload['date']}|${payload['slot']}|${payload['zone']}";
  final key = utf8.encode(QR_SECRET);
  final bytes = utf8.encode(data);
  final hmac = Hmac(sha256, key);
  return hmac.convert(bytes).toString().substring(0, 10); // short sig
}

String generateQrData({
  required String kid,
  required String date,
  required String slot,
  required String zone,
}) {
  final payload = {
    "kid": kid,
    "date": date,
    "slot": slot,
    "zone": zone,
  };

  payload["sig"] = generateSignature(payload);

  final jsonStr = jsonEncode(payload);
  return base64Encode(utf8.encode(jsonStr));
}
