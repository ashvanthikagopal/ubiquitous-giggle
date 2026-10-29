import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// ─── Theme Constants ──────────────────────────────────────────────────────────
const kPrimary = Color(0xFFD32F2F);
const kPrimaryLight = Color(0xFFFFEBEE);
const kSuccess = Color(0xFF2E7D32);
const kSuccessLight = Color(0xFFE8F5E9);
const kWarning = Color(0xFFF57C00);
const kWarningLight = Color(0xFFFFF3E0);
const kInfo = Color(0xFF1565C0);
const kInfoLight = Color(0xFFE3F2FD);
const kBorder = Color(0xFFE0E0E0);
const kBg = Color(0xFFF5F5F5);
const kText = Color(0xFF212121);
const kTextMuted = Color(0xFF757575);

// ─── API Base URL ─────────────────────────────────────────────────────────────
const kApiBase = 'http://192.168.1.5:5148';

// ─── Models ───────────────────────────────────────────────────────────────────
class UploadSummary {
  final int totalRecords;
  final int successCount;
  final int failedCount;
  final List<String> errors;

  UploadSummary({
    required this.totalRecords,
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });

  factory UploadSummary.fromJson(Map<String, dynamic> json) {
    return UploadSummary(
      totalRecords: (json['totalRows'] as num?)?.toInt() ?? 0,
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  int get duplicateCount => errors
      .where((e) =>
          e.toLowerCase().contains('already exists') ||
          e.toLowerCase().contains('duplicate'))
      .length;

  int get invalidCount => failedCount - duplicateCount;

  /// True only when every row passed — no failures at all.
  bool get canRegister => failedCount == 0 && totalRecords > 0;
}

class PreviewRow {
  final int index;
  final String name;
  final String mobile;
  final String gender;
  final String address;
  final String status;

  PreviewRow({
    required this.index,
    required this.name,
    required this.mobile,
    required this.gender,
    required this.address,
    required this.status,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class BulkPeopleRegistrationScreen extends StatefulWidget {
  const BulkPeopleRegistrationScreen({super.key});

  @override
  State<BulkPeopleRegistrationScreen> createState() =>
      _BulkPeopleRegistrationScreenState();
}

class _BulkPeopleRegistrationScreenState
    extends State<BulkPeopleRegistrationScreen> {
  // 0=Upload, 1=Validate, 2=Preview, 3=Complete, 4=Failed
  int _currentStep = 0;

  PlatformFile? _pickedFile;
  bool _isValidating = false;
  bool _isRegistering = false;
  bool _isDownloading = false;

  UploadSummary? _summary;
  List<PreviewRow> _previewRows = [];
  int _previewPage = 1;
  static const int _rowsPerPage = 10;

  String? _errorMessage;
  String? _successMessage;

  // ─── File Pick ───────────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _errorMessage = null;
        _summary = null;
        _previewRows = [];
        _currentStep = 0;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _pickedFile = null;
      _summary = null;
      _previewRows = [];
      _currentStep = 0;
      _errorMessage = null;
    });
  }

  // ─── Download Template ────────────────────────────────────────────────────────
  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['People'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final headers = [
        'PeopleId', 'FullName', 'Gender', 'DOB', 'MobileNumber', 'Email',
        'Address', 'District', 'Constituency', 'Taluk', 'Union', 'Panchayat',
        'WardNumber', 'Password',
      ];

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D32F2F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      final exampleRow = [
        'P001', 'Ramesh Kumar', 'Male', '1990-05-15', '9876543210',
        'ramesh@example.com', '12, Anna Nagar', 'Chennai', 'Chennai North',
        'Ambattur', 'Ambattur Union', 'Ambattur Panchayat', '5', 'Password@123',
      ];

      final exampleStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'),
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int col = 0; col < exampleRow.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1));
        cell.value = TextCellValue(exampleRow[col]);
        cell.cellStyle = exampleStyle;
      }

      for (int col = 0; col < headers.length; col++) {
        sheet.setColumnWidth(col, 20.0);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel file');

      final Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir.createSync(recursive: true);
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final filePath = '${dir.path}/people_template.xlsx';
      await File(filePath).writeAsBytes(bytes);

      setState(() => _isDownloading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template saved to: $filePath'),
            backgroundColor: kSuccess,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: kPrimary,
          ),
        );
      }
    }
  }

  // ─── Validate & Upload ────────────────────────────────────────────────────────
  Future<void> _validateData() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      setState(() => _errorMessage = 'Please choose a file first.');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _currentStep = 1;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kApiBase/api/people/bulk-upload'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'ExcelFile',
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw Exception('Request timed out. Check your network connection.'),
      );

      final body = await streamed.stream.bytesToString();

      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        throw Exception('Invalid response from server:\n$body');
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format. Got: ${decoded.runtimeType}');
      }

      final summary = UploadSummary.fromJson(decoded);

      final errorRowMap = <int, String>{};
      for (final e in summary.errors) {
        final match = RegExp(r'Row (\d+):').firstMatch(e);
        if (match != null) {
          final rowNum = int.tryParse(match.group(1) ?? '') ?? -1;
          if (rowNum > 0) errorRowMap[rowNum] = e;
        }
      }

      final rows = <PreviewRow>[];
      for (int i = 2; i <= summary.totalRecords + 1; i++) {
        final hasError = errorRowMap.containsKey(i);
        rows.add(PreviewRow(
          index: i - 1,
          name: 'Row $i',
          mobile: '-',
          gender: '-',
          address: '-',
          status: hasError
              ? (errorRowMap[i]!.toLowerCase().contains('already exists')
                  ? 'duplicate'
                  : 'invalid')
              : 'valid',
        ));
      }

      setState(() {
        _summary = summary;
        _previewRows = rows;
        _currentStep = 2;
        _isValidating = false;
        _previewPage = 1;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isValidating = false;
        _currentStep = 0;
      });
    }
  }

  // ─── Register (confirm) ──────────────────────────────────────────────────────
  Future<void> _register() async {
    final s = _summary;
    if (s == null) return;

    // Block registration if there are any errors
    if (!s.canRegister) {
      setState(() => _currentStep = 4); // go to failed state
      return;
    }

    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    // Registration already happened on validate; just show completion.
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRegistering = false;
      _currentStep = 3;
      _successMessage = '${s.successCount} people registered successfully.';
    });
  }

  // ─── Pagination helpers ──────────────────────────────────────────────────────
  int get _totalPages =>
      (_previewRows.length / _rowsPerPage).ceil().clamp(1, 999);

  List<PreviewRow> get _currentPageRows {
    final start = (_previewPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _previewRows.length);
    return _previewRows.sublist(start, end);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 16),
            if (_currentStep == 3)
              _buildCompleteCard()
            else if (_currentStep == 4)
              _buildFailedCard()
            else ...[
              _buildDropZoneCard(),
              const SizedBox(height: 12),
              if (_pickedFile != null) _buildFileChip(),
              const SizedBox(height: 12),
              _buildDownloadTemplateCard(),
              if (_summary != null || _previewRows.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildUploadSummaryCard(),
                const SizedBox(height: 16),
                _buildPreviewTable(),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(_errorMessage!),
              ],
              const SizedBox(height: 20),
              _buildBottomActions(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: const BackButton(color: kText),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Bulk People Registration',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: kText),
          ),
          Text(
            'Dashboard > People > Bulk Registration',
            style: TextStyle(
                fontSize: 10, color: kPrimary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.history, size: 14, color: kPrimary),
            label: const Text('History',
                style: TextStyle(color: kPrimary, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step Indicator ──────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = [
      ('Upload', 'Upload Excel'),
      ('Validate', 'Validate data'),
      ('Preview', 'Preview & confirm'),
      (_currentStep == 4 ? 'Failed' : 'Complete',
          _currentStep == 4 ? 'Has errors' : 'Done'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Excel File',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Follow the steps below to register people in bulk.',
              style: TextStyle(color: kTextMuted, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (i) {
              final active = i == _currentStep ||
                  (i == 3 && _currentStep == 4); // step 4 lights step 3
              final done = i < _currentStep && _currentStep != 4;
              final isFailed = i == 3 && _currentStep == 4;

              Color circleFill;
              Color circleBorder;
              Widget circleChild;

              if (isFailed) {
                circleFill = kPrimary;
                circleBorder = kPrimary;
                circleChild = const Icon(Icons.close,
                    size: 14, color: Colors.white);
              } else if (done) {
                circleFill = kPrimary;
                circleBorder = kPrimary;
                circleChild = const Icon(Icons.check,
                    size: 14, color: Colors.white);
              } else {
                circleFill = active ? kPrimary : Colors.white;
                circleBorder = active ? kPrimary : kBorder;
                circleChild = Text('${i + 1}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : kTextMuted));
              }

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: circleFill,
                              border:
                                  Border.all(color: circleBorder, width: 1.5),
                            ),
                            child: Center(child: circleChild),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            steps[i].$1,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: (active || done || isFailed)
                                    ? (isFailed ? kPrimary : kPrimary)
                                    : kTextMuted),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            steps[i].$2,
                            style: const TextStyle(
                                fontSize: 9, color: kTextMuted),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 16,
                        height: 1.5,
                        margin: const EdgeInsets.only(bottom: 28),
                        color: i < _currentStep ? kPrimary : kBorder,
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Drop Zone ───────────────────────────────────────────────────────────────
  Widget _buildDropZoneCard() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: kPrimaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimary, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: kPrimary, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'Drag and drop your Excel file here',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('or', style: TextStyle(color: kTextMuted, fontSize: 13)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: kPrimary),
                foregroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              ),
              child: const Text('Choose File',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Only .xlsx, .xls files are allowed. Maximum file size: 10MB',
              style: TextStyle(color: kTextMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── File Chip ───────────────────────────────────────────────────────────────
  Widget _buildFileChip() {
    final sizeKB = (_pickedFile!.size / 1024).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kSuccessLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kSuccess.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kSuccess,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('X',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_pickedFile!.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text('$sizeKB KB',
                    style: const TextStyle(color: kTextMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.check_circle, color: kSuccess, size: 16),
          const SizedBox(width: 4),
          const Text('Ready',
              style: TextStyle(color: kSuccess, fontSize: 12)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _removeFile,
            child: const Icon(Icons.delete_outline,
                color: kTextMuted, size: 20),
          ),
        ],
      ),
    );
  }

  // ─── Download Template Card ──────────────────────────────────────────────────
  Widget _buildDownloadTemplateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Download Template',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 4),
                Text(
                  'Download the template and fill in the details to register people in bulk.',
                  style: TextStyle(color: kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isDownloading ? null : _downloadTemplate,
            icon: _isDownloading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download, size: 16, color: Colors.white),
            label: const Text('Download',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Upload Summary ──────────────────────────────────────────────────────────
  Widget _buildUploadSummaryCard() {
    final s = _summary;
    final hasErrors = (s?.failedCount ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasErrors ? kPrimary.withOpacity(0.4) : kBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Upload Summary',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              // Validation result badge
              if (s != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: s.canRegister ? kSuccessLight : kPrimaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: s.canRegister
                          ? kSuccess.withOpacity(0.4)
                          : kPrimary.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s.canRegister
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 13,
                        color: s.canRegister ? kSuccess : kPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.canRegister
                            ? 'Ready to Register'
                            : 'Cannot Register',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: s.canRegister ? kSuccess : kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  icon: Icons.table_rows_outlined,
                  iconColor: kPrimary,
                  iconBg: kPrimaryLight,
                  label: 'Total',
                  value: '${s?.totalRecords ?? 0}',
                ),
              ),
              Expanded(
                child: _summaryTile(
                  icon: Icons.check_circle_outline,
                  iconColor: kSuccess,
                  iconBg: kSuccessLight,
                  label: 'Valid',
                  value: '${s?.successCount ?? 0}',
                ),
              ),
              Expanded(
                child: _summaryTile(
                  icon: Icons.warning_amber_outlined,
                  iconColor: kWarning,
                  iconBg: kWarningLight,
                  label: 'Invalid',
                  value: '${s?.invalidCount ?? 0}',
                ),
              ),
              Expanded(
                child: _summaryTile(
                  icon: Icons.info_outline,
                  iconColor: kInfo,
                  iconBg: kInfoLight,
                  label: 'Duplicate',
                  value: '${s?.duplicateCount ?? 0}',
                ),
              ),
            ],
          ),
          // "Cannot register" inline warning when errors exist
          if (s != null && !s.canRegister) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimary.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.block, color: kPrimary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registration not allowed',
                          style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.failedCount} row${s.failedCount > 1 ? 's' : ''} '
                          'contain errors. Fix all errors in the Excel file '
                          'and re-upload to proceed.',
                          style: const TextStyle(
                              color: kPrimary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (s != null && s.errors.isNotEmpty) ...[
            const Divider(height: 20),
            GestureDetector(
              onTap: () => _showErrors(s.errors),
              child: Row(
                children: const [
                  Text('View Errors',
                      style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Spacer(),
                  Icon(Icons.chevron_right, color: kPrimary, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: kTextMuted, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: kText)),
      ],
    );
  }

  // ─── Preview Table ───────────────────────────────────────────────────────────
  Widget _buildPreviewTable() {
    final rows = _currentPageRows;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preview Data',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Review before confirming.',
                          style: TextStyle(
                              color: kTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isValidating ? null : _validateData,
                  icon: _isValidating
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kPrimary))
                      : const Icon(Icons.refresh, size: 14, color: kPrimary),
                  label: const Text('Re-validate',
                      style: TextStyle(color: kPrimary, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            color: kBg,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: const [
                SizedBox(
                    width: 28,
                    child: Text('#',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: kTextMuted))),
                Expanded(
                    flex: 3,
                    child: Text('Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: kTextMuted))),
                Expanded(
                    flex: 3,
                    child: Text('Mobile',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: kTextMuted))),
                Expanded(
                    flex: 2,
                    child: Text('Gender',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: kTextMuted))),
                SizedBox(
                    width: 66,
                    child: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: kTextMuted),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: Text('No data to preview',
                      style: TextStyle(color: kTextMuted))),
            )
          else
            ...rows.map((r) => _buildTableRow(r)),
          const Divider(height: 1),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildTableRow(PreviewRow row) {
    late Color statusColor;
    late Color statusBg;
    late String statusLabel;
    switch (row.status) {
      case 'invalid':
        statusColor = kWarning;
        statusBg = kWarningLight;
        statusLabel = 'Invalid';
        break;
      case 'duplicate':
        statusColor = kInfo;
        statusBg = kInfoLight;
        statusLabel = 'Duplicate';
        break;
      default:
        statusColor = kSuccess;
        statusBg = kSuccessLight;
        statusLabel = 'Valid';
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                  width: 28,
                  child: Text('${row.index}',
                      style:
                          const TextStyle(fontSize: 12, color: kTextMuted))),
              Expanded(
                  flex: 3,
                  child: Text(row.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
              Expanded(
                  flex: 3,
                  child: Text(row.mobile,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
              Expanded(
                  flex: 2,
                  child: Text(row.gender,
                      style: const TextStyle(fontSize: 12))),
              SizedBox(
                width: 66,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 14, endIndent: 14),
      ],
    );
  }

  // ─── Pagination ──────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    final pages = _totalPages;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text('Total: ${_previewRows.length} rows',
              style: const TextStyle(color: kTextMuted, fontSize: 11)),
          const Spacer(),
          _pageBtn(Icons.chevron_left,
              _previewPage > 1 ? () => setState(() => _previewPage--) : null),
          ...List.generate(pages > 5 ? 3 : pages, (i) {
            final p = i + 1;
            return _pageNumBtn(p, p == _previewPage);
          }),
          if (pages > 5) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text('...', style: TextStyle(color: kTextMuted)),
            ),
            _pageNumBtn(pages, pages == _previewPage),
          ],
          _pageBtn(
              Icons.chevron_right,
              _previewPage < pages
                  ? () => setState(() => _previewPage++)
                  : null),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(6),
          color: onTap == null ? kBg : Colors.white,
        ),
        child: Icon(icon,
            size: 16, color: onTap == null ? kTextMuted : kText),
      ),
    );
  }

  Widget _pageNumBtn(int page, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _previewPage = page),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.white,
          border: Border.all(color: active ? kPrimary : kBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text('$page',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : kText)),
        ),
      ),
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: kPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(color: kPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  // ─── Bottom Actions ───────────────────────────────────────────────────────────
  Widget _buildBottomActions() {
    final bool canProceed = _pickedFile != null;
    final bool showRegister = _currentStep >= 2;
    // Disable "Register People" button when summary has errors
    final bool registerBlocked =
        showRegister && (_summary != null && !_summary!.canRegister);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel',
                style: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Tooltip(
            message: registerBlocked
                ? 'Fix all errors before registering'
                : '',
            child: ElevatedButton(
              // Disable if: no file, currently loading, or register is blocked by errors
              onPressed: (!canProceed || registerBlocked)
                  ? null
                  : showRegister
                      ? (_isRegistering ? null : _register)
                      : (_isValidating ? null : _validateData),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    registerBlocked ? kPrimary.withOpacity(0.35) : kPrimary,
                disabledBackgroundColor: kPrimary.withOpacity(0.35),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isValidating || _isRegistering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (registerBlocked)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.lock_outline,
                                size: 16, color: Colors.white54),
                          ),
                        Text(
                          showRegister ? 'Register People' : 'Validate Data',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Complete Card ────────────────────────────────────────────────────────────
  Widget _buildCompleteCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                const BoxDecoration(color: kSuccessLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: kSuccess, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Registration Complete!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_successMessage ?? '',
              style: const TextStyle(color: kTextMuted, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back to Dashboard',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _pickedFile = null;
                  _summary = null;
                  _previewRows = [];
                  _currentStep = 0;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Upload Another File',
                  style:
                      TextStyle(color: kText, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Failed Card ──────────────────────────────────────────────────────────────
  Widget _buildFailedCard() {
    final s = _summary;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.cancel, color: kPrimary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Registration Failed',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kPrimary)),
          const SizedBox(height: 8),
          Text(
            'Your file contains ${s?.failedCount ?? 0} error${(s?.failedCount ?? 0) > 1 ? 's' : ''}. '
            'Registration cannot proceed until all errors are resolved.',
            style: const TextStyle(color: kTextMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Error summary chips
          if (s != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (s.invalidCount > 0)
                  _failSummaryChip(
                    '${s.invalidCount} Invalid',
                    kWarning,
                    kWarningLight,
                    Icons.warning_amber_outlined,
                  ),
                if (s.invalidCount > 0 && s.duplicateCount > 0)
                  const SizedBox(width: 10),
                if (s.duplicateCount > 0)
                  _failSummaryChip(
                    '${s.duplicateCount} Duplicate',
                    kInfo,
                    kInfoLight,
                    Icons.info_outline,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // View errors button
          if (s != null && s.errors.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _showErrors(s.errors),
              icon: const Icon(Icons.list_alt, size: 16, color: kPrimary),
              label: const Text('View All Errors',
                  style: TextStyle(
                      color: kPrimary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'How to fix',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _fixStep(1, 'Download the template again if needed.'),
          _fixStep(2, 'Fix all highlighted errors in your Excel file.'),
          _fixStep(3, 'Remove any duplicate entries.'),
          _fixStep(4, 'Re-upload the corrected file and validate again.'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _pickedFile = null;
                  _summary = null;
                  _previewRows = [];
                  _currentStep = 0;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              icon: const Icon(Icons.upload_file,
                  size: 18, color: Colors.white),
              label: const Text('Upload Corrected File',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back to Dashboard',
                  style:
                      TextStyle(color: kText, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _failSummaryChip(
      String label, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _fixStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary.withOpacity(0.3)),
            ),
            child: Center(
              child: Text('$step',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kPrimary)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 13, color: kTextMuted)),
          ),
        ],
      ),
    );
  }

  // ─── View Errors Bottom Sheet ─────────────────────────────────────────────────
  void _showErrors(List<String> errors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Errors (${errors.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: errors.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.error_outline,
                              color: kPrimary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(errors[i],
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}