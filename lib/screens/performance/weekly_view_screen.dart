import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/providers/performance_provider.dart';


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name}\'s Weekly Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectStartOfWeek(context),
          ),
        ],
      ),
      body: Consumer<PerformanceProvider>(
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