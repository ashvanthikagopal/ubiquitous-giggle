import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpScreen> createState() =>
      _OtpScreenState();
}

class _OtpScreenState
    extends State<OtpScreen> {
  final otpController =
      TextEditingController();

  bool loading = false;

  int seconds = 45;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (seconds == 0) {
          timer.cancel();
        } else {
          setState(() {
            seconds--;
          });
        }
      },
    );
  }

 

Future<void> verifyOtp() async {
  if (otpController.text.trim().length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Enter valid 6 digit OTP"),
      ),
    );
    return;
  }

  setState(() {
    loading = true;
  });

  try {
    final response = await http.post(
      Uri.parse(
        "http://192.168.1.5:5148/api/auth/verify-otp",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": widget.email,
        "otp": otpController.text.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    setState(() {
      loading = false;
    });

    if (response.statusCode == 200) {
      /// SAVE ADMIN ID
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        "adminId",
        data["adminId"].toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            data["message"] ??
                "OTP Verified Successfully",
          ),
        ),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DashboardScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            data["message"] ??
                "Invalid OTP",
          ),
        ),
      );
    }
  } catch (e) {
    setState(() {
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text("Error: $e"),
      ),
    );
  }
}

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme =
        PinTheme(
      width: 55,
      height: 65,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(
            0xffFF4B5C,
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                            context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(
                            0xffFF4B5C),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Icon(
                  Icons.people_alt_rounded,
                  size: 90,
                  color:
                      Colors.red.shade400,
                ),

                const SizedBox(height: 20),

                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Makkal ",
                        style: TextStyle(
                          color: Color(
                              0xff1F2937),
                          fontSize: 40,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "Connect",
                        style: TextStyle(
                          color: Colors
                              .red
                              .shade400,
                          fontSize: 40,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  width: 120,
                  height: 120,
                  decoration:
                      BoxDecoration(
                    color: const Color(
                        0xffFFF3F4),
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    size: 60,
                    color:
                        Color(0xffFF4B5C),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Verify Your Email",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  "Enter the 6-digit OTP sent to",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  widget.email,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color:
                        Color(0xffFF4B5C),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 40),

                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    "OTP",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Pinput(
                  controller:
                      otpController,
                  length: 6,
                  defaultPinTheme:
                      defaultPinTheme,
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    const Text(
                      "Didn't receive OTP? ",
                    ),
                    Text(
                      seconds == 0
                          ? "Resend OTP"
                          : "Resend OTP in 00:${seconds.toString().padLeft(2, '0')}",
                      style:
                          const TextStyle(
                        color: Color(
                            0xffFF4B5C),
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Container(
                  padding:
                      const EdgeInsets.all(
                          16),
                  decoration:
                      BoxDecoration(
                    color: const Color(
                        0xffFFF5F5),
                    borderRadius:
                        BorderRadius
                            .circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Color(
                            0xffFF4B5C),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "For your security, please do not share the OTP with anyone.",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width:
                      double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : verifyOtp,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                              0xffFF4057),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    16),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors
                                .white,
                          )
                        : const Text(
                            "Verify OTP",
                            style:
                                TextStyle(
                              color: Colors
                                  .white,
                              fontSize:
                                  22,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                        context);
                  },
                  icon: const Icon(
                    Icons.email_outlined,
                  ),
                  label: const Text(
                    "Change Email",
                  ),
                  style:
                      OutlinedButton
                          .styleFrom(
                    minimumSize:
                        const Size(
                            double.infinity,
                            60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}