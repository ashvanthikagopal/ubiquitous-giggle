class AdminModel {
  final int adminId;
  final String adminName;
  final String mobileNumber;
  final String email;

  AdminModel({
    required this.adminId,
    required this.adminName,
    required this.mobileNumber,
    required this.email,
  });

  factory AdminModel.fromJson(
      Map<String, dynamic> json) {
    return AdminModel(
      adminId: json["adminId"] ?? 0,
      adminName: json["adminName"] ?? "",
      mobileNumber:
          json["mobileNumber"] ?? "",
      email: json["email"] ?? "",
    );
  }
}