import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final adminNameController =
      TextEditingController();

  final mobileController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool agreeTerms = false;
  bool hidePassword = true;
  bool loading = false;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "http://192.168.1.5:5148/api/admin",
        ),
        headers: {
          "Content-Type":
              "application/json",
        },
        body: jsonEncode({
          "adminName":
              adminNameController.text.trim(),
          "mobileNumber":
              mobileController.text.trim(),
          "email":
              emailController.text.trim(),
          "password":
              passwordController.text.trim(),
        }),
      );

      final data =
          jsonDecode(response.body);

      setState(() {
        loading = false;
      });

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              data["message"] ??
                  "Admin Registered Successfully",
            ),
          ),
        );

if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const LoginScreen(),
  ),
);

        setState(() {
          agreeTerms = false;
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              data["message"] ??
                  "Registration Failed",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

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

  InputDecoration fieldDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              const Color(0xffFFF1F2),
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color:
              const Color(0xffFF4B5C),
        ),
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: Color(0xffD9DDE4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),

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
                          fontSize: 42,
                          fontWeight:
                              FontWeight.bold,
                          color: Color(
                              0xff1F2937),
                        ),
                      ),
                      TextSpan(
                        text: "Connect",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors
                              .red
                              .shade400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors
                            .red
                            .shade200,
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      child: Text(
                        "Admin Registration",
                        style: TextStyle(
                          color:
                              Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors
                            .red
                            .shade200,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller:
                      adminNameController,
                  validator: (value) {
                    if (value == null ||
                        value.trim()
                            .isEmpty) {
                      return "Admin Name is required";
                    }
                    return null;
                  },
                  decoration:
                      fieldDecoration(
                    "Admin Name",
                    Icons.person_outline,
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller:
                      mobileController,
                  keyboardType:
                      TextInputType.phone,
                  validator: (value) {
                    if (value == null ||
                        value.trim()
                            .isEmpty) {
                      return "Mobile Number is required";
                    }

                    if (value.length !=
                        10) {
                      return "Enter valid mobile number";
                    }

                    return null;
                  },
                  decoration:
                      fieldDecoration(
                    "Mobile Number",
                    Icons.phone_outlined,
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller:
                      emailController,
                  validator: (value) {
                    if (value == null ||
                        value.trim()
                            .isEmpty) {
                      return "Email is required";
                    }

                    if (!RegExp(
                      r'^[^@]+@[^@]+\.[^@]+',
                    ).hasMatch(value)) {
                      return "Enter valid email";
                    }

                    return null;
                  },
                  decoration:
                      fieldDecoration(
                    "Email Address",
                    Icons.email_outlined,
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller:
                      passwordController,
                  obscureText:
                      hidePassword,
                  validator: (value) {
                    if (value == null ||
                        value.trim()
                            .isEmpty) {
                      return "Password is required";
                    }

                    if (value.length <
                        6) {
                      return "Minimum 6 characters";
                    }

                    return null;
                  },
                  decoration:
                      fieldDecoration(
                    "Password",
                    Icons.lock_outline,
                  ).copyWith(
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
                  ),
                ),


                const SizedBox(height: 15),

                SizedBox(
                  width:
                      double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : register,
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
                            "Register",
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
                  onPressed: () {},
                  icon: const Icon(
                    Icons.security,
                  ),
                  label: const Text(
                    "Secure Admin Access",
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

                const SizedBox(height: 30),

               Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "Already have an account? ",
      style: TextStyle(
        fontSize: 16,
      ),
    ),

    GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      },
      child: const Text(
        "Login",
        style: TextStyle(
          color: Color(0xffFF4057),
          fontWeight: FontWeight.bold,
          fontSize: 16,
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