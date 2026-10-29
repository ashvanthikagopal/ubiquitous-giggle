import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "http://192.168.1.5:5148/api";

  /// LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "role": "Admin",
        "email": email,
        "password": password,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  /// REGISTER
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "role": "Admin",
        "name": name,
        "email": email,
        "mobileNumber": mobile,
        "password": password,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  /// VERIFY OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  /// DISTRICTS
  Future<List<dynamic>> getDistricts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/district"),
    );

    return jsonDecode(response.body);
  }

  /// TALUKS
  Future<List<dynamic>> getTaluks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/taluk"),
    );

    return jsonDecode(response.body);
  }

  /// TALUK BY DISTRICT
  Future<List<dynamic>> getTaluksByDistrict(
      String districtName) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/taluk/district/$districtName",
      ),
    );

    return jsonDecode(response.body);
  }

  /// UNIONS
  Future<List<dynamic>> getUnions() async {
    final response = await http.get(
      Uri.parse("$baseUrl/union"),
    );

    return jsonDecode(response.body);
  }

  /// UNION SEARCH
  Future<List<dynamic>> getUnionsByTaluk(
    String districtName,
    String talukName,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/union/search?districtName=$districtName&talukName=$talukName",
      ),
    );

    return jsonDecode(response.body);
  }

  /// PANCHAYATS
  Future<List<dynamic>> getPanchayats() async {
    final response = await http.get(
      Uri.parse("$baseUrl/panchayat"),
    );

    return jsonDecode(response.body);
  }

  /// PANCHAYAT SEARCH
  Future<List<dynamic>> getPanchayatSearch(
    String districtName,
    String talukName,
    String unionName,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/panchayat/search?"
        "districtName=$districtName"
        "&talukName=$talukName"
        "&unionName=$unionName",
      ),
    );

    return jsonDecode(response.body);
  }

  /// CREATE DISTRICT
  Future<Map<String, dynamic>> createDistrict(
      String districtName) async {
    final response = await http.post(
      Uri.parse("$baseUrl/district"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "districtName": districtName,
      }),
    );

    return jsonDecode(response.body);
  }

  /// CREATE TALUK
  Future<Map<String, dynamic>> createTaluk({
    required String districtName,
    required String talukName,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/taluk"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "districtName": districtName,
        "talukName": talukName,
      }),
    );

    return jsonDecode(response.body);
  }

  /// CREATE UNION
  Future<Map<String, dynamic>> createUnion({
    required String districtName,
    required String talukName,
    required String unionName,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/union"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "districtName": districtName,
        "talukName": talukName,
        "unionName": unionName,
      }),
    );

    return jsonDecode(response.body);
  }

  /// CREATE PANCHAYAT
  Future<Map<String, dynamic>> createPanchayat({
    required String districtName,
    required String talukName,
    required String unionName,
    required String panchayatName,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/panchayat"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "districtName": districtName,
        "talukName": talukName,
        "unionName": unionName,
        "panchayatName": panchayatName,
      }),
    );

    return jsonDecode(response.body);
  }

  /// CREATE CONSTITUENCY
  Future<Map<String, dynamic>>
      createConstituency({
    required String districtName,
    required String talukName,
    required String unionName,
    required String panchayatName,
    required String constituencyName,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/constituency"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "districtName": districtName,
        "talukName": talukName,
        "unionName": unionName,
        "panchayatName": panchayatName,
        "constituencyName":
            constituencyName,
      }),
    );

    return jsonDecode(response.body);
  }
}