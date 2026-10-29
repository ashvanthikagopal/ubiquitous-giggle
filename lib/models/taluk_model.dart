class TalukModel {
  final int talukId;
  final String talukName;
  final String districtName;
  final String constituencyName;

  TalukModel({
    required this.talukId,
    required this.talukName,
    required this.districtName,
    required this.constituencyName,
  });

  factory TalukModel.fromJson(
      Map<String, dynamic> json) {
    return TalukModel(
      talukId: json["talukId"] ?? 0,
      talukName: json["talukName"] ?? "",
      districtName:
          json["districtName"] ?? "",
      constituencyName:
          json["constituencyName"] ?? "",
    );
  }
}