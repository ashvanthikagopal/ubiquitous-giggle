class ConstituencyModel {
  final int id;
  final String districtName;
  final String constituencyName;

  ConstituencyModel({
    required this.id,
    required this.districtName,
    required this.constituencyName,
  });

  factory ConstituencyModel.fromJson(
      Map<String, dynamic> json) {
    return ConstituencyModel(
      id: json["id"] ?? 0,
      districtName:
          json["districtName"] ?? "",
      constituencyName:
          json["constituencyName"] ?? "",
    );
  }
}