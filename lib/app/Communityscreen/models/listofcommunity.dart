class CommunityZoneModel {
  final int zoneId;
  final String zoneName;
  final String zoneType;
  final Boundary boundary;

  CommunityZoneModel({
    required this.zoneId,
    required this.zoneName,
    required this.zoneType,
    required this.boundary,
  });

  factory CommunityZoneModel.fromJson(Map<String, dynamic> json) {
    return CommunityZoneModel(
      zoneId: json['zoneId'],
      zoneName: json['zoneName'],
      zoneType: json['zoneType'],
      boundary: Boundary.fromJson(json['boundary']),
    );
  }
}

class Boundary {
  final String type;
  final List<dynamic> coordinates;

  Boundary({required this.type, required this.coordinates});

  factory Boundary.fromJson(Map<String, dynamic> json) {
    return Boundary(type: json['type'], coordinates: json['coordinates']);
  }
}
