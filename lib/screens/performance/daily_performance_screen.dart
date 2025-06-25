import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sabaq/models/performance.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/providers/performance_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import './monthly_view_screen.dart';
import './weekly_view_screen.dart';

class DailyPerformanceScreen extends StatefulWidget {
  final Student student;

  const DailyPerformanceScreen({super.key, required this.student});

  @override
  State<DailyPerformanceScreen> createState() => _DailyPerformanceScreenState();
}

class _DailyPerformanceScreenState extends State<DailyPerformanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _sabaq = false;
  bool _sabqi = false;
  bool _manzil = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPerformance() async {
    await context.read<PerformanceProvider>().loadDailyPerformances(
      widget.student.id!,
      _selectedDate,
    );
    // Update checkbox states and description based on loaded performance
    final performances = context
        .read<PerformanceProvider>()
        .getDailyPerformances(widget.student.id!, _selectedDate);
    if (performances.isNotEmpty) {
      final performance = performances.first;
      setState(() {
        _sabaq = performance.sabaq;
        _sabqi = performance.sabqi;
        _manzil = performance.manzil;
        _descriptionController.text = performance.description ?? '';
      });
    } else {
      // Clear states and description if no performance found for the date
      setState(() {
        _sabaq = false;
        _sabqi = false;
        _manzil = false;
        _descriptionController.text = '';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadPerformance(); // Load performance for the newly selected date
    }
  }

  Future<void> _savePerformance() async {
    final performance = Performance(
      studentId: widget.student.id!,
      date: _selectedDate,
      sabaq: _sabaq,
      sabqi: _sabqi,
      manzil: _manzil,
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
    );
    await context.read<PerformanceProvider>().addPerformance(performance);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance saved successfully!')),
      );
    }
    await _loadPerformance(); // Reload to reflect saved changes
  }

  Future<void> _sharePerformanceAsPdf() async {
    final pdf = pw.Document();
    final studentName = widget.student.name;
    final formattedDate = DateFormat('MMMM d, y').format(_selectedDate);
    final sabaqStatus = _sabaq ? 'Yes' : 'No';
    final sabqiStatus = _sabqi ? 'Yes' : 'No';
    final manzilStatus = _manzil ? 'Yes' : 'No';
    final description = _descriptionController.text.trim();

    pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Performance Report")),
              pw.Paragraph(text: 'Student: $studentName'),
              pw.Paragraph(text: 'Date: $formattedDate'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Category', 'Status'],
                  <String>['Sabaq (New Lesson)', sabaqStatus],
                  <String>['Sabqi (Revision)', sabqiStatus],
                  <String>['Manzil (Retention)', manzilStatus],
                ],
              ),
              if (description.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Notes:",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Paragraph(text: description),
                    ],
                  ),
                ),
            ],
          );
        }));

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/performance_report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Performance Report for $studentName');
  }

  void _sharePerformance() {
    final studentName = widget.student.name;
    final formattedDate = DateFormat('MMMM d, y').format(_selectedDate);
    final sabaqStatus = _sabaq ? 'Yes' : 'No';
    final sabqiStatus = _sabqi ? 'Yes' : 'No';
    final manzilStatus = _manzil ? 'Yes' : 'No';
    final description = _descriptionController.text.trim();

    final shareText = '''
Performance Report for: $studentName
Date: $formattedDate

- Sabaq (New Lesson): $sabaqStatus
- Sabqi (Revision): $sabqiStatus
- Manzil (Retention): $manzilStatus
${description.isNotEmpty ? '\nNotes:\n$description' : ''}
''';

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePerformanceAsPdf,
          ),
          // Weekly View Icon
          IconButton(
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => WeeklyViewScreen(student: widget.student),
                ),
              );
            },
          ),
          // Monthly View Icon
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => MonthlyViewScreen(student: widget.student),
                ),
              );
            },
          ),
          // Daily Date Picker Icon
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.student.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${DateFormat('MMMM d, y').format(_selectedDate)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text('Sabaq (New Lesson)'),
                value: _sabaq,
                onChanged: (bool? value) {
                  setState(() {
                    _sabaq = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Sabqi (Revision)'),
                value: _sabqi,
                onChanged: (bool? value) {
                  setState(() {
                    _sabqi = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Manzil (Retention)'),
                value: _manzil,
                onChanged: (bool? value) {
                  setState(() {
                    _manzil = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (e.g., Surah, Ayahs)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _savePerformance,
                  child: const Text('Save Performance'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
