import 'dart:async';
import 'package:flutter/material.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 3),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const OnboardingScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [

          /// TOP LEFT CIRCLE
          Positioned(
            top: -180,
            left: -180,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade50,
              ),
            ),
          ),

          Positioned(
            top: -140,
            left: -140,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.shade100,
                ),
              ),
            ),
          ),

          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.shade100,
                ),
              ),
            ),
          ),

          /// TOP RIGHT DOTS
          Positioned(
            top: 90,
            right: 45,
            child: _buildDots(),
          ),


          /// RIGHT CIRCLES
          Positioned(
            right: -60,
            bottom: 250,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.shade50,
                ),
              ),
            ),
          ),

          Positioned(
            right: -30,
            bottom: 280,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.shade50,
                ),
              ),
            ),
          ),

          /// BOTTOM WAVES
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BackWaveClipper(),
              child: Container(
                height: 230,
                color: Colors.red.shade50,
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: FrontWaveClipper(),
              child: Container(
                height: 170,
                color: Colors.red.shade100,
              ),
            ),
          ),

          /// CENTER CONTENT
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  /// LOGO
                  Icon(
                    Icons.people_alt_rounded,
                    size: 100,
                    color: Colors.red.shade400,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Makkal",
                    style: TextStyle(
                      fontSize: 58,
                      fontWeight:
                          FontWeight.bold,
                      color: Color(
                          0xff2F3B4C),
                    ),
                  ),

                  Text(
                    "Connect",
                    style: TextStyle(
                      fontSize: 58,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.red.shade400,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Container(
                        width: 70,
                        height: 2,
                        color:
                            Colors.red.shade300,
                      ),

                      const SizedBox(width: 12),

                      Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color: Colors
                              .red.shade400,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        width: 70,
                        height: 2,
                        color:
                            Colors.red.shade300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    "Connect. Manage. Empower.",
                    style: TextStyle(
                      fontSize: 20,
                      color:
                          Color(0xff4A5568),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return SizedBox(
      width: 70,
      height: 70,
      child: GridView.builder(
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount: 25,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemBuilder: (_, __) {
          return Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.red.shade300,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// BACK WAVE

class BackWaveClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {

    Path path = Path();

    path.lineTo(
      0,
      size.height * .35,
    );

    path.quadraticBezierTo(
      size.width * .25,
      size.height * .05,
      size.width * .50,
      size.height * .35,
    );

    path.quadraticBezierTo(
      size.width * .75,
      size.height * .60,
      size.width,
      size.height * .20,
    );

    path.lineTo(
      size.width,
      size.height,
    );

    path.lineTo(
      0,
      size.height,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
          CustomClipper<Path> oldClipper) =>
      false;
}

/// FRONT WAVE

class FrontWaveClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {

    Path path = Path();

    path.lineTo(
      0,
      size.height * .45,
    );

    path.quadraticBezierTo(
      size.width * .30,
      size.height * .90,
      size.width * .60,
      size.height * .45,
    );

    path.quadraticBezierTo(
      size.width * .85,
      size.height * .10,
      size.width,
      size.height * .35,
    );

    path.lineTo(
      size.width,
      size.height,
    );

    path.lineTo(
      0,
      size.height,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
          CustomClipper<Path> oldClipper) =>
      false;
}