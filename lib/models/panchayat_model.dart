class PanchayatModel {
  final int panchayatId;
  final String panchayatName;
  final String districtName;
  final String constituencyName;
  final String talukName;
  final String unionName;

  PanchayatModel({
    required this.panchayatId,
    required this.panchayatName,
    required this.districtName,
    required this.constituencyName,
    required this.talukName,
    required this.unionName,
  });

  factory PanchayatModel.fromJson(
      Map<String, dynamic> json) {
    return PanchayatModel(
      panchayatId:
          json["panchayatId"] ?? 0,
      panchayatName:
          json["panchayatName"] ?? "",
      districtName:
          json["districtName"] ?? "",
      constituencyName:
          json["constituencyName"] ?? "",
      talukName:
          json["talukName"] ?? "",
      unionName:
          json["unionName"] ?? "",
    );
  }
}