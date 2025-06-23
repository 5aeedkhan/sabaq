import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/providers/performance_provider.dart';


class MonthlyViewScreen extends StatefulWidget {
  final Student student;

  const MonthlyViewScreen({super.key, required this.student});

  @override
  State<MonthlyViewScreen> createState() => _MonthlyViewScreenState();
}

class _MonthlyViewScreenState extends State<MonthlyViewScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    await context.read<PerformanceProvider>().loadMonthlyPerformances(
          widget.student.id!,
          _selectedMonth,
        );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      await _loadMonthlyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name}\'s Monthly Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body: Consumer<PerformanceProvider>(
        builder: (context, performanceProvider, child) {
          final performances = performanceProvider.getMonthlyPerformances(
            widget.student.id!,
            _selectedMonth,
          );

          if (performances.isEmpty) {
            return Center(
              child: Text(
                'No records for ${DateFormat('MMMM y').format(_selectedMonth)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

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