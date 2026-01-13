import 'package:hive/hive.dart';

part 'sos_model.g.dart';

@HiveType(typeId: 0)
class SOSModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String issue;

  @HiveField(2)
  double? lat;

  @HiveField(3)
  double? lng;

  @HiveField(4)
  String imagePath;

  @HiveField(5)
  String timestamp;

  @HiveField(6)
  bool isSynced;

  @HiveField(7)
  String encryptedPayload;


  SOSModel({
    required this.id,
    required this.issue,
    required this.lat,
    required this.lng,
    required this.imagePath,
    required this.timestamp,
    required this.encryptedPayload,
    this.isSynced = false,
  });

}
