import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/admin_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  static const String baseUrl =
      "http://192.168.1.5:5148/api";

  AdminModel? admin;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      final adminId =
          prefs.getInt("adminId");

      if (adminId == null) {
        setState(() {
          loading = false;
        });
        return;
      }

      final response =
          await http.get(
        Uri.parse(
          "$baseUrl/auth/$adminId",
        ),
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        admin =
            AdminModel.fromJson(data);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  Widget infoField(
    IconData icon,
    String value,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                const Color(0xffFF4057),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        title: const Text(
          "Profile",
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : admin == null
              ? const Center(
                  child: Text(
                    "Profile Not Found",
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets
                          .all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [

                      const Text(
                        "Profile",
                        style:
                            TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      const Text(
                        "View and manage your profile information.",
                        style:
                            TextStyle(
                          color:
                              Colors.grey,
                          fontSize:
                              16,
                        ),
                      ),

                      const SizedBox(
                          height: 25),

                      Container(
                        width: double
                            .infinity,
                        padding:
                            const EdgeInsets
                                .all(
                                20),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white,
                          borderRadius:
                              BorderRadius.circular(
                                  20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .grey
                                  .shade200,
                              blurRadius:
                                  10,
                            )
                          ],
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [

                            const Text(
                              "Admin Information",
                              style:
                                  TextStyle(
                                fontSize:
                                    22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height:
                                    25),

                            Row(
                              children: [

                                CircleAvatar(
                                  radius:
                                      40,
                                  backgroundColor:
                                      const Color(
                                          0xffFFF1F2),
                                  child:
                                      const Icon(
                                    Icons
                                        .person,
                                    size:
                                        50,
                                    color:
                                        Color(
                                            0xffFF4057),
                                  ),
                                ),

                                const SizedBox(
                                    width:
                                        20),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        admin!
                                            .adminName,
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              28,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              5),

                                      const Text(
                                        "Super Admin",
                                        style:
                                            TextStyle(
                                          color:
                                              Color(
                                                  0xffFF4057),
                                          fontSize:
                                              18,
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              8),

                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              12,
                                          vertical:
                                              6,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              const Color(0xffFFF1F2),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                        ),
                                        child:
                                            Text(
                                          "Admin ID : ${admin!.adminId}",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height:
                                    30),

                            infoField(
                              Icons.person_outline,
                              admin!
                                  .adminName,
                            ),

                            infoField(
                              Icons.phone,
                              admin!
                                  .mobileNumber,
                            ),

                            infoField(
                              Icons.email,
                              admin!
                                  .email,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 25),

                      Container(
                        width: double
                            .infinity,
                        padding:
                            const EdgeInsets
                                .all(
                                20),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white,
                          borderRadius:
                              BorderRadius.circular(
                                  20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .grey
                                  .shade200,
                              blurRadius:
                                  10,
                            )
                          ],
                        ),
                        child:
                            Column(
                          children: [

                            Row(
                              children: [

                                const Icon(
                                  Icons
                                      .badge_outlined,
                                ),

                                const SizedBox(
                                    width:
                                        10),

                                const Text(
                                  "Admin ID",
                                ),

                                const Spacer(),

                                Text(
                                  admin!
                                      .adminId
                                      .toString(),
                                ),
                              ],
                            ),

                            const Divider(),

                            Row(
                              children: const [

                                Icon(Icons
                                    .security),

                                SizedBox(
                                    width:
                                        10),

                                Text(
                                  "Role",
                                ),

                                Spacer(),

                                Text(
                                  "Super Admin",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 30),

                      SizedBox(
                        width: double
                            .infinity,
                        height: 55,
                        child:
                            ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                    0xffFF4057),
                          ),
                          onPressed:
                              () {
                            Navigator.pop(
                                context);
                          },
                          icon:
                              const Icon(
                            Icons
                                .arrow_back,
                            color: Colors
                                .white,
                          ),
                          label:
                              const Text(
                            "Back To Dashboard",
                            style:
                                TextStyle(
                              color: Colors
                                  .white,
                              fontSize:
                                  18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}