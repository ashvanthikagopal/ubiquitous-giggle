import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/taluk_model.dart';

class TalukScreen extends StatefulWidget {
  const TalukScreen({super.key});

  @override
  State<TalukScreen> createState() => _TalukScreenState();
}

class _TalukScreenState extends State<TalukScreen> {
  final talukController = TextEditingController();
  final searchController = TextEditingController();

  List districts = [];
  List filteredConstituencies = [];

  String? selectedDistrict;
  String? selectedConstituency;

  List<TalukModel> taluks = [];
  List<TalukModel> filteredTaluks = [];

  bool loading = true;

  int currentPage = 1;
  final int pageSize = 5;

  final String baseUrl = "http://192.168.1.5:5148";

  @override
  void initState() {
    super.initState();
    loadDistricts();
    loadTaluks();
  }

  Future loadDistricts() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/district"));
      if (response.statusCode == 200) {
        setState(() => districts = jsonDecode(response.body));
      }
    } catch (_) {}
  }

  Future loadConstituencies(String districtName) async {
    try {
      final response = await http.get(Uri.parse(
          "$baseUrl/api/constituency/district/$districtName"));
      if (response.statusCode == 200) {
        setState(
            () => filteredConstituencies = jsonDecode(response.body));
      }
    } catch (_) {}
  }

  Future loadTaluks() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/taluk"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        taluks =
            data.map<TalukModel>((e) => TalukModel.fromJson(e)).toList();
        filteredTaluks = taluks;
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  Future createTaluk() async {
    if (selectedDistrict == null ||
        selectedConstituency == null ||
        talukController.text.trim().isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/api/taluk"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "talukName": talukController.text.trim(),
        "districtName": selectedDistrict,
        "constituencyName": selectedConstituency,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _resetForm();
      await loadTaluks();
      _showMessage("Taluk Created Successfully");
    }
  }

  Future deleteTaluk(int id) async {
    await http.delete(Uri.parse("$baseUrl/api/taluk/$id"));
    loadTaluks();
  }

  Future editTaluk(TalukModel taluk) async {
    final nameController =
        TextEditingController(text: taluk.talukName);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Taluk",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Enter taluk name",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red)),
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
            child:
                const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await http.put(
                Uri.parse("$baseUrl/api/taluk/${taluk.talukId}"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "talukName": nameController.text.trim(),
                  "districtName": taluk.districtName,
                  "constituencyName": taluk.constituencyName,
                }),
              );
              if (!mounted) return;
              Navigator.pop(context);
              loadTaluks();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Update",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    talukController.clear();
    setState(() {
      selectedDistrict = null;
      selectedConstituency = null;
      filteredConstituencies = [];
    });
  }

  void _searchTaluk(String value) {
    setState(() {
      currentPage = 1;
      filteredTaluks = taluks.where((e) {
        return e.talukName.toLowerCase().contains(value.toLowerCase()) ||
            e.districtName.toLowerCase().contains(value.toLowerCase()) ||
            e.constituencyName
                .toLowerCase()
                .contains(value.toLowerCase());
      }).toList();
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  List<TalukModel> get pagedList {
    final start = (currentPage - 1) * pageSize;
    final end =
        (start + pageSize).clamp(0, filteredTaluks.length);
    return filteredTaluks.isEmpty
        ? []
        : filteredTaluks.sublist(start, end);
  }

  int get totalPages =>
      (filteredTaluks.length / pageSize).ceil().clamp(1, 999);

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
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.red))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page heading
                        const Text("Create Taluk",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("Add a new taluk to the system.",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 20),

                        // ── Create card ───────────────────────
                        _buildCreateCard(),
                        const SizedBox(height: 20),

                        // ── List card ─────────────────────────
                        _buildListCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Back to Dashboard ─────────────────────────
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // District
          _fieldLabel("District Name"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedDistrict,
            isExpanded: true,
            decoration: _dropdownDecoration(
                "Select district", Icons.location_on_outlined),
            items: districts
                .map<DropdownMenuItem<String>>(
                  (d) => DropdownMenuItem(
                    value: d["districtName"] as String,
                    child: Text(d["districtName"] as String,
                        overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              setState(() {
                selectedDistrict = value;
                selectedConstituency = null;
                filteredConstituencies = [];
              });
              await loadConstituencies(value!);
            },
          ),

          const SizedBox(height: 16),

          // Constituency
          _fieldLabel("Constituency Name"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedConstituency,
            isExpanded: true,
            decoration: _dropdownDecoration(
                "Select constituency", Icons.flag_outlined),
            items: filteredConstituencies
                .map<DropdownMenuItem<String>>(
                  (e) => DropdownMenuItem(
                    value: e["constituencyName"] as String,
                    child: Text(e["constituencyName"] as String,
                        overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => selectedConstituency = value),
          ),

          const SizedBox(height: 16),

          // Taluk Name
          _fieldLabel("Taluk Name"),
          const SizedBox(height: 8),
          TextField(
            controller: talukController,
            decoration: InputDecoration(
              hintText: "Enter taluk name",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.apartment_outlined,
                    color: Colors.red, size: 17),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.close,
                      color: Colors.red, size: 16),
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
                  onPressed: createTaluk,
                  icon: const Icon(Icons.add,
                      color: Colors.white, size: 16),
                  label: const Text("Create Taluk",
                      style:
                          TextStyle(color: Colors.white, fontSize: 13)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + search
          Row(
            children: [
              const Text("Taluk List",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              SizedBox(
                width: 160,
                height: 38,
                child: TextField(
                  controller: searchController,
                  onChanged: _searchTaluk,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "Search taluk...",
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: Colors.grey),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: Colors.red)),
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
                    width: 24,
                    child: Text("#",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12))),
                Expanded(
                    flex: 3,
                    child: Text("Taluk Name",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12))),
                Expanded(
                    flex: 3,
                    child: Text("District Name",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12))),
                Expanded(
                    flex: 3,
                    child: Text("Constituency",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12))),
                Text("Actions",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),

          // Table rows
          ...List.generate(pagedList.length, (index) {
            final item = pagedList[index];
            final globalIndex =
                (currentPage - 1) * pageSize + index + 1;
            final isLast = index == pagedList.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 24,
                          child: Text("$globalIndex",
                              style: const TextStyle(fontSize: 12))),
                      Expanded(
                          flex: 3,
                          child: Text(item.talukName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                      Expanded(
                          flex: 3,
                          child: Text(item.districtName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                      Expanded(
                          flex: 3,
                          child: Text(item.constituencyName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                      // Edit btn
                      _actionBtn(
                        icon: Icons.edit_outlined,
                        color: Colors.grey,
                        bgColor: Colors.white,
                        borderColor: const Color(0xFFE0E0E0),
                        onTap: () => editTaluk(item),
                      ),
                      const SizedBox(width: 5),
                      // Delete btn
                      _actionBtn(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        bgColor: const Color(0xFFFFF5F5),
                        borderColor: const Color(0xFFFFCCCC),
                        onTap: () => deleteTaluk(item.talukId),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────
  Widget _buildPagination() {
    final start = filteredTaluks.isEmpty
        ? 0
        : (currentPage - 1) * pageSize + 1;
    final end =
        (currentPage * pageSize).clamp(0, filteredTaluks.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Showing $start to $end of ${filteredTaluks.length} entries",
          style: const TextStyle(color: Colors.grey, fontSize: 11),
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
              if (currentPage < totalPages)
                setState(() => currentPage++);
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
      for (int p in [1, 2, 3]) {
        pages.add(_pageNumBtn(p));
        pages.add(const SizedBox(width: 4));
      }
      pages.add(const Text("...",
          style: TextStyle(color: Colors.grey, fontSize: 12)));
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
        child: Text("$page",
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            )),
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

  // ── Bottom Button ─────────────────────────────────────────────
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
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

  InputDecoration _dropdownDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: const Color(0xFFFFEDED),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.red, size: 17),
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
    );
  }
}