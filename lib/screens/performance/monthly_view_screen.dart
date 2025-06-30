import 'package:flutter/material.dart';
import '../../models/student.dart';
import 'performance_period_screen.dart';

class MonthlyViewScreen extends StatelessWidget {
  final Student student;

  const MonthlyViewScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return PerformancePeriodScreen(
      student: student,
      periodType: PeriodType.monthly,
    );
  }
} 