import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/district_model.dart';

class DistrictScreen extends StatefulWidget {
  const DistrictScreen({super.key});

  @override
  State<DistrictScreen> createState() => _DistrictScreenState();
}

class _DistrictScreenState extends State<DistrictScreen> {
  final TextEditingController districtController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<DistrictModel> districts = [];
  List<DistrictModel> filtered = [];

  bool loading = true;

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 5;

  final String baseUrl = "http://192.168.1.5:5148/api/district";

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  Future<void> loadDistricts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        districts = data.map((e) => DistrictModel.fromJson(e)).toList();
        filtered = districts;
      }
      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> createDistrict() async {
    if (districtController.text.trim().isEmpty) return;

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"districtName": districtController.text.trim()}),
    );

    final data = jsonDecode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"])),
    );

    districtController.clear();
    loadDistricts();
  }

  Future<void> updateDistrict(DistrictModel district) async {
    TextEditingController controller =
        TextEditingController(text: district.districtName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Update District",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter district name",
            prefixIcon:
                const Icon(Icons.location_on_outlined, color: Colors.red),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await http.put(
                Uri.parse("$baseUrl/${district.id}"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({"districtName": controller.text.trim()}),
              );
              Navigator.pop(context);
              loadDistricts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteDistrict(int id) async {
    await http.delete(Uri.parse("$baseUrl/$id"));
    loadDistricts();
  }

  void searchDistrict(String value) {
    setState(() {
      currentPage = 1;
      filtered = districts
          .where((e) =>
              e.districtName.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  List<DistrictModel> get pagedDistricts {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get totalPages => (filtered.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ── Top App Bar ──────────────────────────────────────────
     appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,

  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back,
      color: Colors.red,
    ),
    onPressed: () => Navigator.pop(context),
  ),

  titleSpacing: 0,

  title: Row(
    children: [

      Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.people,
          color: Colors.white,
          size: 20,
        ),
      ),

      const SizedBox(width: 8),

      const Expanded(
        child: Text(
          "Makkal Connect",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
    ],
  ),

  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Icon(
            Icons.person_outline,
            color: Colors.red,
            size: 20,
          ),

          const SizedBox(width: 4),

          const Text(
            "Admin",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey,
          ),
        ],
      ),
    ),
  ],
),

      // ── Body ─────────────────────────────────────────────────
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page heading
                        const Text(
                          "District Creation",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Add a new district.",
                          style:
                              TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 20),

                        // ── Create card ───────────────────────
                        _buildCreateCard(),

                        const SizedBox(height: 20),

                        // ── List card ─────────────────────────
                        _buildListCard(),
                      ],
                    ),
                  ),
                ),

                // ── Back to Dashboard button ──────────────────
                _buildBottomButton(),
              ],
            ),
    );
  }

  // ── Create District Card ──────────────────────────────────────
  Widget _buildCreateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "District Name ",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                TextSpan(
                  text: "*",
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Text field
          TextField(
            controller: districtController,
            decoration: InputDecoration(
              hintText: "Enter district name",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: Colors.red, size: 18),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => districtController.clear(),
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  label: const Text("Reset",
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: createDistrict,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text("Create District",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── District List Card ────────────────────────────────────────
  Widget _buildListCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + search
          Row(
            children: [
              const Text(
                "District List",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 180,
                height: 40,
                child: TextField(
                  controller: searchController,
                  onChanged: searchDistrict,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search district...",
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: Colors.grey),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text("#",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text("District Name",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text("Actions",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Table rows
          ...List.generate(pagedDistricts.length, (index) {
            final district = pagedDistricts[index];
            final globalIndex =
                (currentPage - 1) * itemsPerPage + index + 1;
            final isLast = index == pagedDistricts.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text("$globalIndex",
                            style:
                                const TextStyle(color: Colors.black87)),
                      ),
                      Expanded(
                        child: Text(district.districtName,
                            style:
                                const TextStyle(color: Colors.black87)),
                      ),
                      // Edit button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: Colors.grey),
                          onPressed: () => updateDistrict(district),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFFFCCCC)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFFFF5F5),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          onPressed: () => deleteDistrict(district.id),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
              ],
            );
          }),

          const SizedBox(height: 12),

          // Pagination
          _buildPagination(),
        ],
      ),
    );
  }

  // ── Pagination Row ────────────────────────────────────────────
  Widget _buildPagination() {
    final start =
        filtered.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final end =
        (currentPage * itemsPerPage).clamp(0, filtered.length);

    return Row(
      children: [
        Text(
          "Showing $start to $end of ${filtered.length} entries",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
        _pageBtn(Icons.chevron_left, () {
          if (currentPage > 1) setState(() => currentPage--);
        }),
        const SizedBox(width: 4),
        ...List.generate(totalPages > 5 ? 5 : totalPages, (i) {
          // Show pages 1,2,3,…,last when totalPages > 4
          int page;
          if (totalPages <= 5) {
            page = i + 1;
          } else {
            // simplified: always show 1,2,3,…,totalPages
            if (i < 3) {
              page = i + 1;
            } else if (i == 3) {
              // ellipsis placeholder — render as disabled
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: const TextStyle(color: Colors.grey)),
              );
            } else {
              page = totalPages;
            }
          }
          final isActive = page == currentPage;
          return GestureDetector(
            onTap: () => setState(() => currentPage = page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? Colors.red : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isActive
                    ? null
                    : Border.all(color: const Color(0xFFE0E0E0)),
              ),
              alignment: Alignment.center,
              child: Text(
                "$page",
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: isActive
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        _pageBtn(Icons.chevron_right, () {
          if (currentPage < totalPages) setState(() => currentPage++);
        }),
      ],
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Icon(icon, size: 18, color: Colors.red),
      ),
    );
  }

  // ── Back to Dashboard button ──────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        label: const Text("Back to Dashboard",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}