// To parse this JSON data, do
//
//     final zoneModel = zoneModelFromJson(jsonString);

import 'dart:convert';

ZoneModel zoneModelFromJson(String str) => ZoneModel.fromJson(json.decode(str));

String zoneModelToJson(ZoneModel data) => json.encode(data.toJson());

class ZoneModel {
  bool? success;
  Zone? zone;
  bool? isZoneAvailable;
  String? message;

  ZoneModel({
    this.success,
    this.zone,
    this.isZoneAvailable,
    this.message,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) => ZoneModel(
    success: json["success"],
    zone: json["zone"] == null ? null : Zone.fromJson(json["zone"]),
    isZoneAvailable: json["is_zone_available"],
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "zone": zone?.toJson(),
    "is_zone_available": isZoneAvailable,
    "message": message,
  };
}

class Zone {
  String? id;
  String? name;
  String? latitude;
  String? longitude;
  bool? publish;
  List<Area>? area;

  Zone({
    this.id,
    this.name,
    this.latitude,
    this.longitude,
    this.publish,
    this.area,
  });

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id: json["id"],
    name: json["name"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    publish: json["publish"],
    area: json["area"] == null ? [] : List<Area>.from(json["area"]!.map((x) => Area.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "latitude": latitude,
    "longitude": longitude,
    "publish": publish,
    "area": area == null ? [] : List<dynamic>.from(area!.map((x) => x.toJson())),
  };
}

class Area {
  double? latitude;
  double? longitude;

  Area({
    this.latitude,
    this.longitude,
  });

  factory Area.fromJson(Map<String, dynamic> json) => Area(
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
  };
}
