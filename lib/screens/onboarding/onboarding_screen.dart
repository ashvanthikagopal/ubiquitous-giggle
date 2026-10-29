import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {
  final PageController _pageController =
      PageController();

  int currentPage = 0;

  final List<Map<String, dynamic>> pages = [
    {
      "icon": Icons.account_balance_outlined,
      "title1": "Centralized",
      "title2": "Constituency Management",
      "description":
          "Manage all constituencies, officials and activities from one centralized platform."
    },
    {
      "icon": Icons.bar_chart_outlined,
      "title1": "Real-time",
      "title2": "Insights & Reports",
      "description":
          "Get real-time updates, analytics and reports to make informed decisions."
    },
    {
      "icon": Icons.task_alt_outlined,
      "title1": "Streamline",
      "title2": "Tasks & Workflow",
      "description":
          "Assign tasks, track progress and ensure timely completion with ease."
    },
  ];

  void nextPage() {
    if (currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration:
            const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      navigateToLogin();
    }
  }

  void navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xffFF5A66),
            ),
            borderRadius:
                BorderRadius.circular(28),
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [

                      /// SKIP
                      Align(
                        alignment:
                            Alignment.topRight,
                        child: TextButton(
                          onPressed:
                              navigateToLogin,
                          child: const Text(
                            "Skip",
                            style: TextStyle(
                              color: Color(
                                  0xffFF5A66),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 40),

                      /// ICON
                      Container(
                        width: 180,
                        height: 180,
                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xffFFF3F4),
                          shape:
                              BoxShape.circle,
                        ),
                        child: Icon(
                          pages[index]["icon"],
                          size: 90,
                          color: const Color(
                              0xffFF5A66),
                        ),
                      ),

                      const SizedBox(
                          height: 40),

                      Text(
                        pages[index]["title1"],
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xff202938),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        pages[index]["title2"],
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xffFF5A66),
                        ),
                      ),

                      const SizedBox(
                          height: 25),

                      Text(
                        pages[index]
                            ["description"],
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          height: 1.6,
                          color:
                              Color(0xff5E6775),
                        ),
                      ),

                      const SizedBox(
                          height: 60),

                      /// DOTS
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children:
                            List.generate(
                          pages.length,
                          (dotIndex) {
                            return AnimatedContainer(
                              duration:
                                  const Duration(
                                      milliseconds:
                                          250),
                              margin:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 6,
                              ),
                              width: 12,
                              height: 12,
                              decoration:
                                  BoxDecoration(
                                shape: BoxShape
                                    .circle,
                                color: currentPage ==
                                        dotIndex
                                    ? const Color(
                                        0xffFF5A66)
                                    : const Color(
                                        0xffFFD5D8),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                          height: 50),

                      Align(
                        alignment:
                            Alignment.centerRight,
                        child:
                            GestureDetector(
                          onTap: nextPage,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration:
                                const BoxDecoration(
                              shape: BoxShape
                                  .circle,
                              gradient:
                                  LinearGradient(
                                colors: [
                                  Color(
                                      0xffFF5A66),
                                  Color(
                                      0xffFF6E78),
                                ],
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .arrow_forward,
                              color:
                                  Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}