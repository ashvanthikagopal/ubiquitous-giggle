import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/district_model.dart';
import '../../models/constituency_model.dart';
import '../../models/taluk_model.dart';
import '../../models/union_model.dart';

class UnionScreen extends StatefulWidget {
  const UnionScreen({super.key});

  @override
  State<UnionScreen> createState() => _UnionScreenState();
}

class _UnionScreenState extends State<UnionScreen> {
  final unionController = TextEditingController();
  final searchController = TextEditingController();

  List<DistrictModel> districts = [];
  List<ConstituencyModel> constituencies = [];
  List<TalukModel> taluks = [];
  List<UnionModel> unions = [];
  List<UnionModel> filteredUnions = [];

  String? selectedDistrict;
  String? selectedConstituency;
  String? selectedTaluk;

  bool loading = false;

  int currentPage = 1;
  final int pageSize = 5;

  static const String baseUrl = "http://192.168.1.5v:5148/api";

  @override
  void initState() {
    super.initState();
    loadDistricts();
    loadConstituencies();
    loadTaluks();
    loadUnions();
  }

  Future<void> loadDistricts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/district"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          districts =
              data.map((e) => DistrictModel.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> loadConstituencies() async {
    try {
      String url = "$baseUrl/constituency";
      if (selectedDistrict != null) {
        url =
            "$baseUrl/constituency/district/$selectedDistrict";
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          constituencies =
              data.map((e) => ConstituencyModel.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> loadTaluks() async {
    try {
      String url = "$baseUrl/taluk";
      if (selectedDistrict != null || selectedConstituency != null) {
        url =
            "$baseUrl/taluk/filter?districtName=$selectedDistrict&constituencyName=$selectedConstituency";
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          taluks = data.map((e) => TalukModel.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> loadUnions() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/union"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          unions = data.map((e) => UnionModel.fromJson(e)).toList();
          filteredUnions = List.from(unions);
        });
      }
    } catch (_) {}
  }

  Future<void> createUnion() async {
    if (selectedDistrict == null ||
        selectedConstituency == null ||
        selectedTaluk == null ||
        unionController.text.trim().isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/union"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "unionName": unionController.text.trim(),
          "districtName": selectedDistrict,
          "constituencyName": selectedConstituency,
          "talukName": selectedTaluk,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        await loadUnions();
        _showMessage("Union Created Successfully");
      }
    } catch (_) {}

    setState(() => loading = false);
  }

  Future<void> deleteUnion(int unionId) async {
    await http.delete(Uri.parse("$baseUrl/union/$unionId"));
    loadUnions();
  }

  Future<void> editUnion(UnionModel union) async {
    final nameController =
        TextEditingController(text: union.unionName);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Union",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Enter union name",
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
                Uri.parse("$baseUrl/union/${union.unionId}"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "unionName": nameController.text.trim(),
                  "districtName": union.districtName,
                  "constituencyName": union.constituencyName,
                  "talukName": union.talukName,
                }),
              );
              if (!mounted) return;
              Navigator.pop(context);
              loadUnions();
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
    unionController.clear();
    setState(() {
      selectedDistrict = null;
      selectedConstituency = null;
      selectedTaluk = null;
      constituencies = [];
      taluks = [];
    });
  }

  void searchUnion(String value) {
    setState(() {
      currentPage = 1;
      filteredUnions = unions
          .where((e) =>
              e.unionName.toLowerCase().contains(value.toLowerCase()) ||
              e.districtName
                  .toLowerCase()
                  .contains(value.toLowerCase()) ||
              e.constituencyName
                  .toLowerCase()
                  .contains(value.toLowerCase()) ||
              e.talukName.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  List<UnionModel> get pagedList {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filteredUnions.length);
    return filteredUnions.isEmpty ? [] : filteredUnions.sublist(start, end);
  }

  int get totalPages =>
      (filteredUnions.length / pageSize).ceil().clamp(1, 999);

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
                  const Text("Union Creation",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Add a new union.",
                      style:
                          TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),

                  // ── Create card ───────────────────────────
                  _buildCreateCard(),
                  const SizedBox(height: 20),

                  // ── List card ─────────────────────────────
                  _buildListCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Back to Dashboard ─────────────────────────────
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
          _styledDropdown<String>(
            hint: "Select district",
            icon: Icons.location_on_outlined,
            value: selectedDistrict,
            items: districts
                .map((e) => DropdownMenuItem(
                    value: e.districtName,
                    child: Text(e.districtName,
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) async {
              setState(() {
                selectedDistrict = value;
                selectedConstituency = null;
                selectedTaluk = null;
                constituencies = [];
                taluks = [];
              });
              await loadConstituencies();
              await loadTaluks();
            },
          ),

          const SizedBox(height: 16),

          // Constituency
          _fieldLabel("Constituency Name"),
          const SizedBox(height: 8),
          _styledDropdown<String>(
            hint: "Select constituency",
            icon: Icons.account_balance_outlined,
            value: selectedConstituency,
            items: constituencies
                .map((e) => DropdownMenuItem(
                    value: e.constituencyName,
                    child: Text(e.constituencyName,
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) async {
              setState(() {
                selectedConstituency = value;
                selectedTaluk = null;
                taluks = [];
              });
              await loadTaluks();
            },
          ),

          const SizedBox(height: 16),

          // Taluk
          _fieldLabel("Taluk Name"),
          const SizedBox(height: 8),
          _styledDropdown<String>(
            hint: "Select taluk",
            icon: Icons.apartment_outlined,
            value: selectedTaluk,
            items: taluks
                .map((e) => DropdownMenuItem(
                    value: e.talukName,
                    child: Text(e.talukName,
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) =>
                setState(() => selectedTaluk = value),
          ),

          const SizedBox(height: 16),

          // Union Name
          _fieldLabel("Union Name"),
          const SizedBox(height: 8),
          TextField(
            controller: unionController,
            decoration: InputDecoration(
              hintText: "Enter union name",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.groups_outlined,
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : createUnion,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add,
                          color: Colors.white, size: 16),
                  label: const Text("Create Union",
                      style: TextStyle(
                          color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
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
          // Header: title + search
          Row(
            children: [
              const Text("Union List",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              SizedBox(
                width: 165,
                height: 38,
                child: TextField(
                  controller: searchController,
                  onChanged: searchUnion,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "Search union...",
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

          // Union rows
          ...List.generate(pagedList.length, (index) {
            final union = pagedList[index];
            final isLast = index == pagedList.length - 1;

            return Column(
              children: [
                _buildUnionRow(union),
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

  // ── Single Union Row ──────────────────────────────────────────
  Widget _buildUnionRow(UnionModel union) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar icon
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: Color(0xFFFFEDED), shape: BoxShape.circle),
            child: const Icon(Icons.groups_outlined,
                color: Colors.red, size: 22),
          ),
          const SizedBox(width: 10),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Union", union.unionName),
                const SizedBox(height: 2),
                _infoRow("District", union.districtName),
                const SizedBox(height: 2),
                _infoRow("Constituency", union.constituencyName),
                const SizedBox(height: 2),
                _infoRow("Taluk", union.talukName),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Edit + Delete buttons (vertical)
          Column(
            children: [
              _labeledActionBtn(
                icon: Icons.edit_outlined,
                label: "Edit",
                color: Colors.grey.shade600,
                borderColor: const Color(0xFFE0E0E0),
                bgColor: Colors.white,
                onTap: () => editUnion(union),
              ),
              const SizedBox(height: 6),
              _labeledActionBtn(
                icon: Icons.delete_outline,
                label: "Delete",
                color: Colors.red,
                borderColor: const Color(0xFFFFCCCC),
                bgColor: const Color(0xFFFFF5F5),
                onTap: () => deleteUnion(union.unionId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 11)),
        ),
        const Text(": ",
            style: TextStyle(color: Colors.grey, fontSize: 11)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _labeledActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color borderColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────
  Widget _buildPagination() {
    final start = filteredUnions.isEmpty
        ? 0
        : (currentPage - 1) * pageSize + 1;
    final end =
        (currentPage * pageSize).clamp(0, filteredUnions.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Showing $start to $end of ${filteredUnions.length} entries",
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
    final widgets = <Widget>[];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(_pageNumBtn(i));
        if (i < totalPages) widgets.add(const SizedBox(width: 4));
      }
    } else {
      for (int p in [1, 2, 3]) {
        widgets.add(_pageNumBtn(p));
        widgets.add(const SizedBox(width: 4));
      }
      widgets.add(const Text("...",
          style: TextStyle(color: Colors.grey, fontSize: 12)));
      widgets.add(const SizedBox(width: 4));
      widgets.add(_pageNumBtn(totalPages));
    }
    return widgets;
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
          border: isActive
              ? null
              : Border.all(color: const Color(0xFFE0E0E0)),
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
        icon:
            const Icon(Icons.arrow_back, color: Colors.white, size: 18),
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

  Widget _styledDropdown<T>({
    required String hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
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
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}