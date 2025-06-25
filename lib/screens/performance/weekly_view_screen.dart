import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/providers/performance_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class WeeklyViewScreen extends StatefulWidget {
  final Student student;

  const WeeklyViewScreen({super.key, required this.student});

  @override
  State<WeeklyViewScreen> createState() => _WeeklyViewScreenState();
}

class _WeeklyViewScreenState extends State<WeeklyViewScreen> {
  DateTime _startOfWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Set _startOfWeek to the beginning of the current week (e.g., Monday)
    final now = DateTime.now();
    _startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    await context.read<PerformanceProvider>().loadWeeklyPerformances(
          widget.student.id!,
          _startOfWeek,
        );
  }

  Future<void> _selectStartOfWeek(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startOfWeek,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow selecting a week up to a year in the future
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) {
      // Calculate the start of the week for the picked date
       final startOfWeek = picked.subtract(Duration(days: picked.weekday - 1));
      setState(() {
        _startOfWeek = startOfWeek;
      });
      await _loadWeeklyData();
    }
  }

  Future<void> _shareWeeklyPerformanceAsPdf() async {
    final performanceProvider = context.read<PerformanceProvider>();
    final performances = performanceProvider.getWeeklyPerformances(
      widget.student.id!,
    );

    if (performances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No performance data to share for this week.')),
      );
      return;
    }

    performances.sort((a, b) => a.date.compareTo(b.date));

    final pdf = pw.Document();
    final studentName = widget.student.name;
    final endOfWeek = _startOfWeek.add(const Duration(days: 6));
    final weekOf =
        '${DateFormat('MMM d, y').format(_startOfWeek)} - ${DateFormat('MMM d, y').format(endOfWeek)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Weekly Performance Report for: $studentName', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Week of: $weekOf', style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
              ]
            )
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 10),
              data: <List<String>>[
                <String>['Date', 'Sabaq', 'Sabqi', 'Manzil', 'Notes'],
                ...performances.map((p) => [
                  DateFormat('EEE, MMM d').format(p.date),
                  p.sabaq ? 'Yes' : 'No',
                  p.sabqi ? 'Yes' : 'No',
                  p.manzil ? 'Yes' : 'No',
                  p.description ?? '',
                ]),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/weekly_performance_report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Weekly Performance Report for $studentName');
  }

  void _shareWeeklyPerformance() {
    final performanceProvider = context.read<PerformanceProvider>();
    final performances = performanceProvider.getWeeklyPerformances(
      widget.student.id!,
    );

    if (performances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No performance data to share for this week.')),
      );
      return;
    }

    performances.sort((a, b) => a.date.compareTo(b.date));

    final studentName = widget.student.name;
    final endOfWeek = _startOfWeek.add(const Duration(days: 6));
    final weekOf =
        '${DateFormat('MMM d, y').format(_startOfWeek)} - ${DateFormat('MMM d, y').format(endOfWeek)}';

    var report = 'Weekly Performance Report for: $studentName\n';
    report += 'Week of: $weekOf\n\n';

    for (final p in performances) {
      final formattedDate = DateFormat('EEEE, MMMM d').format(p.date);
      final sabaqStatus = p.sabaq ? 'Yes' : 'No';
      final sabqiStatus = p.sabqi ? 'Yes' : 'No';
      final manzilStatus = p.manzil ? 'Yes' : 'No';
      final description = p.description ?? '';

      report += '$formattedDate:\n';
      report += '- Sabaq: $sabaqStatus\n';
      report += '- Sabqi: $sabqiStatus\n';
      report += '- Manzil: $manzilStatus\n';
      if (description.isNotEmpty) {
        report += '- Notes: $description\n';
      }
      report += '\n';
    }

    Share.share(report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWeeklyPerformanceAsPdf,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectStartOfWeek(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.student.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: Consumer<PerformanceProvider>(
              builder: (context, performanceProvider, child) {
                final performances = performanceProvider.getWeeklyPerformances(
                  widget.student.id!,
                );

                if (performances.isEmpty) {
                  return Center(
                    child: Text(
                      'No records for the week starting ${DateFormat('MMM d, y').format(_startOfWeek)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                // Sort performances by date
                performances.sort((a, b) => a.date.compareTo(b.date));

                return ListView.builder(
                  itemCount: performances.length,
                  itemBuilder: (context, index) {
                    final performance = performances[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(performance.date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatusChip('Sabaq', performance.sabaq),
                                const SizedBox(width: 8),
                                _buildStatusChip('Sabqi', performance.sabqi),
                                const SizedBox(width: 8),
                                _buildStatusChip('Manzil', performance.manzil),
                              ],
                            ),
                            if (performance.description != null && performance.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Description: ${performance.description!}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isCompleted) {
    return Chip(
      label: Text(label),
      backgroundColor: isCompleted ? Colors.green.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isCompleted ? Colors.green.shade900 : Colors.grey.shade700,
      ),
    );
  }
} 