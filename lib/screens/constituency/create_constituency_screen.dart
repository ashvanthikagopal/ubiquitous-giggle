import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/constituency_model.dart';

class ConstituencyScreen extends StatefulWidget {
  const ConstituencyScreen({super.key});

  @override
  State<ConstituencyScreen> createState() => _ConstituencyScreenState();
}

class _ConstituencyScreenState extends State<ConstituencyScreen> {
  final TextEditingController constituencyController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> districts = [];
  List<ConstituencyModel> constituencies = [];
  List<ConstituencyModel> filteredConstituencies = [];

  String? selectedDistrict;
  bool loading = false;

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 5;

  final String baseUrl = "http://192.168.1.5:5148";

  @override
  void initState() {
    super.initState();
    loadDistricts();
    loadConstituencies();
  }

  Future<void> loadDistricts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/district"));
      if (response.statusCode == 200) {
        setState(() => districts = jsonDecode(response.body));
      }
    } catch (_) {}
  }

  Future<void> loadConstituencies() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/constituency"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        constituencies =
            data.map<ConstituencyModel>((e) => ConstituencyModel.fromJson(e)).toList();
        filteredConstituencies = constituencies;
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> createConstituency() async {
    if (selectedDistrict == null) {
      showMessage("Please Select District");
      return;
    }
    if (constituencyController.text.trim().isEmpty) {
      showMessage("Enter Constituency Name");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/constituency"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "districtName": selectedDistrict,
          "constituencyName": constituencyController.text.trim(),
        }),
      );
      final result = jsonDecode(response.body);
      showMessage(result["message"] ?? result["Message"] ?? "Completed");

      if (response.statusCode == 201 || response.statusCode == 200) {
        reset();
        loadConstituencies();
      }
    } catch (e) {
      showMessage(e.toString());
    }

    setState(() => loading = false);
  }

  Future<void> deleteConstituency(int id) async {
    await http.delete(Uri.parse("$baseUrl/api/constituency/$id"));
    loadConstituencies();
  }

  void reset() {
    constituencyController.clear();
    setState(() => selectedDistrict = null);
  }

  void search(String value) {
    setState(() {
      currentPage = 1;
      filteredConstituencies = constituencies.where((e) {
        return e.constituencyName.toLowerCase().contains(value.toLowerCase()) ||
            e.districtName.toLowerCase().contains(value.toLowerCase());
      }).toList();
    });
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<ConstituencyModel> get pagedList {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, filteredConstituencies.length);
    return filteredConstituencies.sublist(start, end);
  }

  int get totalPages =>
      (filteredConstituencies.length / itemsPerPage).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ── AppBar ────────────────────────────────────────────────
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  const Text("Constituency Creation",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Add a new constituency.",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),

                  // ── Create card ───────────────────────────────
                  _buildCreateCard(),
                  const SizedBox(height: 20),

                  // ── List card ─────────────────────────────────
                  _buildListCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Back to Dashboard ─────────────────────────────────
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ── Create Card ───────────────────────────────────────────────
  Widget _buildCreateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // District Name label
          _fieldLabel("District Name"),
          const SizedBox(height: 8),

          // District dropdown
          DropdownButtonFormField<String>(
            value: selectedDistrict,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: "Select district",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.location_on_outlined,
                    color: Colors.red, size: 17),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            items: districts
                .map<DropdownMenuItem<String>>(
                  (d) => DropdownMenuItem(
                    value: d["districtName"] as String,
                    child: Text(d["districtName"] as String,
                        overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => selectedDistrict = value),
          ),

          const SizedBox(height: 16),

          // Constituency Name label
          _fieldLabel("Constituency Name"),
          const SizedBox(height: 8),

          // Constituency text field
          TextField(
            controller: constituencyController,
            decoration: InputDecoration(
              hintText: "Enter constituency name",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance_outlined,
                    color: Colors.red, size: 17),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
            ),
          ),

          const SizedBox(height: 20),

          // Reset + Create buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reset,
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
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
                  onPressed: loading ? null : createConstituency,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text("Create Constituency",
                      style: TextStyle(color: Colors.white, fontSize: 13)),
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

  // ── List Card ─────────────────────────────────────────────────
  Widget _buildListCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text("Constituency List",
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Search pill
              SizedBox(
                width: 170,
                height: 38,
                child: TextField(
                  controller: searchController,
                  onChanged: search,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "Search constituency...",
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon:
                        const Icon(Icons.search, size: 16, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                SizedBox(
                    width: 28,
                    child: Text("#",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 5,
                    child: Text("Constituency Name",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 4,
                    child: Text("District Name",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Text("Actions",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),

          // Table rows
          ...List.generate(pagedList.length, (index) {
            final item = pagedList[index];
            final globalIndex =
                (currentPage - 1) * itemsPerPage + index + 1;
            final isLast = index == pagedList.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 28,
                          child: Text("$globalIndex",
                              style: const TextStyle(fontSize: 13))),
                      Expanded(
                          flex: 5,
                          child: Text(item.constituencyName,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis)),
                      Expanded(
                          flex: 4,
                          child: Text(item.districtName,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis)),
                      // Edit
                      _actionBtn(
                        icon: Icons.edit_outlined,
                        color: Colors.grey,
                        bgColor: Colors.white,
                        borderColor: const Color(0xFFE0E0E0),
                        onTap: () {
                          // handle edit
                        },
                      ),
                      const SizedBox(width: 6),
                      // Delete
                      _actionBtn(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        bgColor: const Color(0xFFFFF5F5),
                        borderColor: const Color(0xFFFFCCCC),
                        onTap: () => deleteConstituency(item.id),
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

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────
  Widget _buildPagination() {
    final start = filteredConstituencies.isEmpty
        ? 0
        : (currentPage - 1) * itemsPerPage + 1;
    final end =
        (currentPage * itemsPerPage).clamp(0, filteredConstituencies.length);

    return Column(
      children: [
        // "Showing X to Y of Z entries"
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Showing $start to $end of ${filteredConstituencies.length} entries",
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _pageNavBtn(Icons.chevron_left, () {
              if (currentPage > 1) setState(() => currentPage--);
            }),
            const SizedBox(width: 4),
            ..._buildPageNumbers(),
            const SizedBox(width: 4),
            _pageNavBtn(Icons.chevron_right, () {
              if (currentPage < totalPages) setState(() => currentPage++);
            }),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(_pageNumBtn(i));
        if (i < totalPages) pages.add(const SizedBox(width: 4));
      }
    } else {
      // Always show 1, 2, 3, ..., last
      for (int p in [1, 2, 3]) {
        pages.add(_pageNumBtn(p));
        pages.add(const SizedBox(width: 4));
      }
      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text("...", style: TextStyle(color: Colors.grey, fontSize: 13)),
      ));
      pages.add(const SizedBox(width: 4));
      pages.add(_pageNumBtn(totalPages));
    }

    return pages;
  }

  Widget _pageNumBtn(int page) {
    final isActive = page == currentPage;
    return GestureDetector(
      onTap: () => setState(() => currentPage = page),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border:
              isActive ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        alignment: Alignment.center,
        child: Text(
          "$page",
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight:
                isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _pageNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Icon(icon, size: 16, color: Colors.red),
      ),
    );
  }

  // ── Back to Dashboard ─────────────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        label: const Text("Back to Dashboard",
            style: TextStyle(color: Colors.white, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Helper: field label with red asterisk ─────────────────────
  Widget _fieldLabel(String label) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
            text: "$label ",
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const TextSpan(
            text: "*",
            style: TextStyle(color: Colors.red, fontSize: 14)),
      ]),
    );
  }
}