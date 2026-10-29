import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/otp_screen.dart';
import '../auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool rememberMe = false;
  bool hidePassword = true;
  bool loading = false;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email is required"),
        ),
      );
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password is required"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(
          "http://192.168.1.5:5148/api/auth/login",
        ),
        headers: {
          "Content-Type":
              "application/json",
        },
        body: jsonEncode({
          "role": "Admin",
          "email":
              emailController.text.trim(),
          "password": passwordController.text
              .trim(),
        }),
      );

      final data =
          jsonDecode(response.body);

      setState(() => loading = false);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email:
                  emailController.text.trim(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ??
                  "Invalid Credentials",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Icon(
                  Icons.people_alt_rounded,
                  size: 90,
                  color:
                      Colors.red.shade400,
                ),

                const SizedBox(height: 10),

                const Text(
                  "Makkal",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xff1E293B),
                  ),
                ),

                Text(
                  "Connect",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.red.shade400,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color:
                            Colors.red.shade200,
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        "Admin Login",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color:
                            Colors.red.shade200,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller:
                      emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Enter your email",
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors
                          .red.shade400,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller:
                      passwordController,
                  obscureText:
                      hidePassword,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Enter your password",
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors
                          .red.shade400,
                    ),
                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword =
                              !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons
                                .visibility_off
                            : Icons
                                .visibility,
                      ),
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Checkbox(
                      value:
                          rememberMe,
                      activeColor:
                          Colors.red,
                      onChanged: (v) {
                        setState(() {
                          rememberMe =
                              v!;
                        });
                      },
                    ),
                    const Text(
                      "Remember me",
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors
                              .red
                              .shade400,
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width:
                      double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : login,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.red,
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
                            "Login",
                            style:
                                TextStyle(
                              color: Colors
                                  .white,
                              fontSize:
                                  20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: Divider(),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      child: Text(
                        "OR",
                      ),
                    ),
                    Expanded(
                      child: Divider(),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                OutlinedButton.icon(
                  style:
                      OutlinedButton
                          .styleFrom(
                    minimumSize:
                        const Size(
                            double.infinity,
                            60),
                    side: BorderSide(
                      color:
                          Colors.red,
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(
                    Icons.security,
                    color: Colors.red,
                  ),
                  label: const Text(
                    "Secure Admin Access",
                    style: TextStyle(
                      color:
                          Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    const Text(
                      "Not Registered? ",
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Register",
                        style: TextStyle(
                          color: Colors
                              .red
                              .shade400,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}