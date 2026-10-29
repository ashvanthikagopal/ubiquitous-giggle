import 'package:flutter/material.dart';

import '../district/create_district_screen.dart';
import '../constituency/create_constituency_screen.dart';
import '../taluk/create_taluk_screen.dart';
import '../union/create_union_screen.dart';
import '../panchayat/create_panchayat_screen.dart';
import '../profile/profile_screen.dart';
import '../BulkPeopleRegister/bulk_people_register_screen.dart'; // ← add this import

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<Map<String, dynamic>> _menuItems = [
    {
      "title": "District Creation",
      "subtitle": "Create and manage districts.",
      "icon": Icons.location_on_outlined,
    },
    {
      "title": "Constituency Creation",
      "subtitle": "Create and manage constituencies.",
      "icon": Icons.account_balance_outlined,
    },
    {
      "title": "Taluk Creation",
      "subtitle": "Create and manage taluks.",
      "icon": Icons.apartment_outlined,
    },
    {
      "title": "Union Creation",
      "subtitle": "Create and manage unions.",
      "icon": Icons.groups_outlined,
    },
    {
      "title": "Panchayat Creation",
      "subtitle": "Create and manage panchayats.",
      "icon": Icons.home_outlined,
    },
    {
      "title": "Profile",
      "subtitle": "View and update profile information.",
      "icon": Icons.person_outline,
    },
    {
      "title": "People Bulk\nRegistration",
      "subtitle": "Register people in bulk using Excel.",
      "icon": Icons.upload_file_outlined,
    },
  ];

  Widget _getPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        return const DistrictScreen();
      case 1:
        return const ConstituencyScreen();
      case 2:
        return const TalukScreen();
      case 3:
        return const UnionScreen();
      case 4:
        return const PanchayatScreen();
      case 5:
        return const ProfileScreen();
      case 6:
        return const BulkPeopleRegistrationScreen();
      default:
        return const DistrictScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ── AppBar ────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.menu, color: Colors.black87, size: 26),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.people, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Makkal",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.1),
                ),
                Text(
                  "Connect",
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.1),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFEDED), shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline,
                      color: Colors.red, size: 20),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Admin",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    Row(
                      children: [
                        Text("Super Admin",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 11)),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey, size: 14),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome, Admin!",
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Manage master data and settings from here.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Grid of cards — all 7 items, uniform size
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _menuItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      return _buildCard(
                        context,
                        title: item["title"] as String,
                        subtitle: item["subtitle"] as String,
                        icon: item["icon"] as IconData,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => _getPage(context, index)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Logout button ─────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                    color: Color(0xFFFFEDED), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.red, size: 28),
              ),

              const SizedBox(height: 14),

              // Title
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),

              const SizedBox(height: 5),

              // Subtitle
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey, height: 1.4),
                ),
              ),

              // Arrow button aligned bottom-right
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFEDED), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.red, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}