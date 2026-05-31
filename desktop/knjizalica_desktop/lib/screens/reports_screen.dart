import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../screens/book_form_screen.dart';
import '../widgets/data_table.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  bool _isDownloading = false;
  String? _error;
  String? _success;

  Future<void> _savePdf(Uint8List bytes, String defaultName) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF Report',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (path == null) return;

    final file = File(path);
    await file.writeAsBytes(bytes);
    setState(() => _success = 'Report saved to $path');
  }

  Future<void> _downloadOverdueReport() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _success = null;
    });

    try {
      final api = context.read<AuthApiHolder>().api;
      final bytes = await api.downloadOverdueLoansReport();
      await _savePdf(bytes, 'overdue-loans-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to download report.');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadLoansByPeriodReport() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _success = null;
    });

    try {
      final api = context.read<AuthApiHolder>().api;
      final bytes = await api.downloadLoansByPeriodReport(_fromDate, _toDate);
      final name =
          'loans-by-period-${DateFormat('yyyyMMdd').format(_fromDate)}-${DateFormat('yyyyMMdd').format(_toDate)}.pdf';
      await _savePdf(bytes, name);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to download report.');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded)
            const PageHeader(
              title: 'Reports',
              subtitle: 'Download PDF reports for library operations',
            ),
          if (_error != null) ErrorBanner(message: _error!),
          if (_success != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_success!)),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overdue Loans Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PDF listing all currently overdue loans with member and book details.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadOverdueReport,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Overdue Loans PDF'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loans by Period Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PDF summary of loans within a selected date range.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fromDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _fromDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text('From: ${DateFormat.yMMMd().format(_fromDate)}'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _toDate,
                            firstDate: _fromDate,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _toDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text('To: ${DateFormat.yMMMd().format(_toDate)}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadLoansByPeriodReport,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Loans by Period PDF'),
                  ),
                ],
              ),
            ),
          ),
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
