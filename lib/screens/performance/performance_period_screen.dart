import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/student.dart';
import '../../providers/performance_provider.dart';
import '../../services/sharing_service.dart';

enum PeriodType { weekly, monthly }

class PerformancePeriodScreen extends StatefulWidget {
  final Student student;
  final PeriodType periodType;

  const PerformancePeriodScreen({
    super.key,
    required this.student,
    required this.periodType,
  });

  @override
  State<PerformancePeriodScreen> createState() =>
      _PerformancePeriodScreenState();
}

class _PerformancePeriodScreenState extends State<PerformancePeriodScreen> {
  late DateTime _selectedDate;
  final SharingService _sharingService = SharingService();

  @override
  void initState() {
    super.initState();
    _initializeDate();
    _loadData();
  }

  String get _title =>
      widget.periodType == PeriodType.weekly ? 'Weekly Record' : 'Monthly Record';

  String get _appBarTitle =>
      widget.periodType == PeriodType.weekly ? 'Weekly Performance' : 'Monthly Performance';

  String get _noRecordsText {
    if (widget.periodType == PeriodType.weekly) {
      final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      return 'No records for the week starting ${DateFormat('MMM d, y').format(weekStart)}';
    } else {
      return 'No records for ${DateFormat('MMMM y').format(_selectedDate)}';
    }
  }

  void _initializeDate() {
    final now = DateTime.now();
    if (widget.periodType == PeriodType.weekly) {
      // Monday as the start of the week
      _selectedDate = now.subtract(Duration(days: now.weekday - 1));
    } else {
      _selectedDate = DateTime(now.year, now.month, 1);
    }
  }

  Future<void> _loadData() async {
    final performanceProvider = context.read<PerformanceProvider>();
    if (widget.periodType == PeriodType.weekly) {
      await performanceProvider.loadWeeklyPerformances(
          widget.student.id!, _selectedDate);
    } else {
      await performanceProvider.loadMonthlyPerformances(
          widget.student.id!, _selectedDate);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (widget.periodType == PeriodType.weekly) {
          _selectedDate = picked.subtract(Duration(days: picked.weekday - 1));
        } else {
          _selectedDate = DateTime(picked.year, picked.month, 1);
        }
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 24,
          child: Marquee(
            text: _appBarTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 40.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final performanceProvider = context.read<PerformanceProvider>();
              final performances = widget.periodType == PeriodType.monthly
                  ? performanceProvider.getMonthlyPerformances(
                      widget.student.id!, _selectedDate)
                  : performanceProvider
                      .getWeeklyPerformances(widget.student.id!);

              _sharingService.sharePerformanceReport(
                context,
                performances,
                widget.student,
                widget.periodType,
                _selectedDate,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
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
                final performances = widget.periodType == PeriodType.weekly
                    ? performanceProvider.getWeeklyPerformances(widget.student.id!)
                    : performanceProvider.getMonthlyPerformances(widget.student.id!, _selectedDate);

                if (performanceProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (performanceProvider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        performanceProvider.errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (performances.isEmpty) {
                  return Center(
                    child: Text(
                      _noRecordsText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                performances.sort((a, b) => a.date.compareTo(b.date));

                return ListView.builder(
                  itemCount: performances.length,
                  itemBuilder: (context, index) {
                    final performance = performances[index];
                    final descriptions = [
                      if (performance.description?.isNotEmpty ?? false)
                        'Notes: ${performance.description}',
                      if (performance.sabaqDescription?.isNotEmpty ?? false)
                        'Sabaq: ${performance.sabaqDescription}',
                      if (performance.sabqiDescription?.isNotEmpty ?? false)
                        'Sabqi: ${performance.sabqiDescription}',
                      if (performance.manzilDescription?.isNotEmpty ?? false)
                        'Manzil: ${performance.manzilDescription}',
                    ].where((d) => d.isNotEmpty).toList();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, y')
                                  .format(performance.date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildStatusChip(
                                        'Sabaq', performance.sabaq)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _buildStatusChip(
                                        'Sabqi', performance.sabqi)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _buildStatusChip(
                                        'Manzil', performance.manzil)),
                              ],
                            ),
                            if (descriptions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                descriptions.join('\n\n'),
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

  Widget _buildStatusChip(String label, bool isDone) {
    final bgColor = isDone ? Colors.green.shade100 : Colors.red.shade100;
    final iconColor = isDone ? Colors.green.shade700 : Colors.red.shade700;
    final textColor = isDone ? Colors.green.shade900 : Colors.red.shade900;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.cancel,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
} 