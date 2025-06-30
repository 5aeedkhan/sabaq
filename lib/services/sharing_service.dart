import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sabaq/models/performance.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/screens/performance/performance_period_screen.dart';
import 'package:share_plus/share_plus.dart';

class SharingService {
  Future<void> sharePerformanceReport(
    BuildContext context,
    List<Performance> performances,
    Student student,
    PeriodType periodType,
    DateTime selectedDate,
  ) async {
    if (performances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No performance data to share.')),
      );
      return;
    }

    final pdf = await _generatePdf(
        performances, student, periodType, selectedDate);
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/performance_report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Performance Report for ${student.name}',
    );
  }

  String _getPeriodText(PeriodType periodType, DateTime date) {
    if (periodType == PeriodType.weekly) {
      final start = date.subtract(Duration(days: date.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return 'Week of: ${DateFormat('MMM d, y').format(start)} - ${DateFormat('MMM d, y').format(end)}';
    } else {
      return 'Month of: ${DateFormat('MMMM y').format(date)}';
    }
  }

  Future<pw.Document> _generatePdf(
    List<Performance> performances,
    Student student,
    PeriodType periodType,
    DateTime selectedDate,
  ) async {
    final pdf = pw.Document();
    final String reportTitle = periodType == PeriodType.weekly
        ? 'Weekly Performance Report'
        : 'Monthly Performance Report';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => pw.Header(
          level: 0,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$reportTitle for: ${student.name}',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                _getPeriodText(periodType, selectedDate),
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(4),
            },
            data: <List<String>>[
              <String>['Date', 'S', 'S', 'M', 'Notes'],
              ...performances.map((p) {
                final descriptions = [
                  if (p.description?.isNotEmpty ?? false) p.description!,
                  if (p.sabaqDescription?.isNotEmpty ?? false)
                    'Sabaq: ${p.sabaqDescription}',
                  if (p.sabqiDescription?.isNotEmpty ?? false)
                    'Sabqi: ${p.sabqiDescription}',
                  if (p.manzilDescription?.isNotEmpty ?? false)
                    'Manzil: ${p.manzilDescription}',
                ].join('\n');
                return [
                  DateFormat('EEE, MMM d').format(p.date),
                  p.sabaq ? 'Y' : 'N',
                  p.sabqi ? 'Y' : 'N',
                  p.manzil ? 'Y' : 'N',
                  descriptions,
                ];
              }),
            ],
          ),
        ],
      ),
    );
    return pdf;
  }
} 