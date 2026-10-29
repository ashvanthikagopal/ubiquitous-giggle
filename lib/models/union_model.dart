class UnionModel {
  final int unionId;
  final String unionName;
  final String districtName;
  final String constituencyName;
  final String talukName;

  UnionModel({
    required this.unionId,
    required this.unionName,
    required this.districtName,
    required this.constituencyName,
    required this.talukName,
  });

  factory UnionModel.fromJson(
      Map<String, dynamic> json) {
    return UnionModel(
      unionId: json["unionId"] ?? 0,
      unionName: json["unionName"] ?? "",
      districtName: json["districtName"] ?? "",
      constituencyName:
          json["constituencyName"] ?? "",
      talukName: json["talukName"] ?? "",
    );
  }
}