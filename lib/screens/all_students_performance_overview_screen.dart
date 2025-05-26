import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/performance.dart';
import '../providers/student_provider.dart';
import '../providers/performance_provider.dart';

class AllStudentsPerformanceOverviewScreen extends StatefulWidget {
  const AllStudentsPerformanceOverviewScreen({super.key});

  @override
  State<AllStudentsPerformanceOverviewScreen> createState() => _AllStudentsPerformanceOverviewScreenState();
}

class _AllStudentsPerformanceOverviewScreenState extends State<AllStudentsPerformanceOverviewScreen> {
  List<Student> _students = [];
  List<DateTime> _recentDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial data load
    // We no longer need this here as loadData is called in initState and on refresh
    // if (_students.isEmpty) {
    //   _loadData();
    // }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load students
      final studentProvider = context.read<StudentProvider>();
      // No need to await here as we listen via watch
      studentProvider.loadStudents(); // Assuming loadStudents updates the provider state

      if (!mounted) return;

      // Access students from the provider after loading
      _students = studentProvider.students;

      // Determine recent dates (e.g., last 5 days)
      _recentDates = List.generate(5, (index) {
        return DateTime.now().subtract(Duration(days: index));
      }).reversed.toList();

      // Load performance for each student for each of the recent dates
      if (_students.isNotEmpty && _recentDates.isNotEmpty) {
        await context.read<PerformanceProvider>().loadOverviewPerformances(
          _students.map((s) => s.id!).toList(),
          _recentDates,
        );
        // The screen will get updated performances via context.watch
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to get performance for a specific student and date - Reads directly from provider state
  Performance? _getPerformance(BuildContext context, int studentId, DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    // Read directly from the provider's state
    final performancesForStudent = context.watch<PerformanceProvider>().overviewPerformances[studentId];
    return performancesForStudent?[dateString];
  }

  // Helper to update performance for a specific student and date
  Future<void> _updatePerformance({
    required Student student,
    required DateTime date,
    bool? sabaq,
    bool? sabqi,
    bool? manzil,
    String? description,
  }) async {
    // Read existing performance directly from the provider state
    Performance? existingPerformance = context.read<PerformanceProvider>().overviewPerformances[student.id!]?[DateFormat('yyyy-MM-dd').format(date)];

    Performance newPerformance;
    if (existingPerformance != null) {
      // Update existing performance
      newPerformance = Performance(
        id: existingPerformance.id,
        studentId: student.id!,
        date: date,
        sabaq: sabaq ?? existingPerformance.sabaq,
        sabqi: sabqi ?? existingPerformance.sabqi,
        manzil: manzil ?? existingPerformance.manzil,
        description: description ?? existingPerformance.description,
      );
    } else {
      // Create new performance
      newPerformance = Performance(
        studentId: student.id!,
        date: date,
        sabaq: sabaq ?? false,
        sabqi: sabqi ?? false,
        manzil: manzil ?? false,
        description: description,
      );
    }

    try {
      // Use the provider to add/update the performance
      await context.read<PerformanceProvider>().addPerformance(newPerformance);
      // The provider will call notifyListeners, triggering a rebuild of this screen
    } catch (e) {
      print('ASPOS: Error saving performance from overview: $e');
    }
  }

  // Function to show full description in a dialog
  void _showFullDescription(BuildContext context, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Full Description'),
          content: SingleChildScrollView(
            child: Text(description),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the PerformanceProvider for changes. This will trigger rebuilds.
    // We no longer store performances in local state (_performances)
    context.watch<PerformanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Students Performance Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students added yet.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      dataRowMaxHeight: 100.0,
                      columns: [
                        const DataColumn(label: Text('Student Name')),
                        for (var date in _recentDates)
                          DataColumn(label: Text(DateFormat('d-MMM').format(date))),
                      ],
                      rows: [
                        for (var student in _students)
                          DataRow(
                            cells: [
                              DataCell(Text(student.name)),
                              for (var date in _recentDates)
                                DataCell(
                                  // Pass context to _buildPerformanceCell to allow reading provider
                                  _buildPerformanceCell(context, student, date),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Updated _buildPerformanceCell to accept BuildContext
  Widget _buildPerformanceCell(BuildContext context, Student student, DateTime date) {
    // Read the performance directly from the provider state via _getPerformance
    final performance = _getPerformance(context, student.id!, date);
    final bool sabaq = performance?.sabaq ?? false;
    final bool sabqi = performance?.sabqi ?? false;
    final bool manzil = performance?.manzil ?? false;
    final String description = performance?.description ?? '';

    // Define maximum length for displayed description
    // const int maxDescriptionLength = 50; // Adjust as needed
    // final String displayedDescription = description.length > maxDescriptionLength
    //     ? '${description.substring(0, maxDescriptionLength)}...'
    //     : description;

    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Sabaq checkbox
              Column(
                children: [
                  const Text('S', style: TextStyle(fontSize: 12)),
                  Checkbox(
                    value: sabaq,
                    onChanged: (bool? value) async {
                      await _updatePerformance(
                        student: student,
                        date: date,
                        sabaq: value ?? false,
                      );
                    },
                  ),
                ],
              ),
              // Sabqi checkbox
              Column(
                children: [
                  const Text('Sb', style: TextStyle(fontSize: 12)),
                  Checkbox(
                    value: sabqi,
                    onChanged: (bool? value) async {
                      await _updatePerformance(
                        student: student,
                        date: date,
                        sabqi: value ?? false,
                      );
                    },
                  ),
                ],
              ),
              // Manzil checkbox
              Column(
                children: [
                  const Text('M', style: TextStyle(fontSize: 12)),
                  Checkbox(
                    value: manzil,
                    onChanged: (bool? value) async {
                      await _updatePerformance(
                        student: student,
                        date: date,
                        manzil: value ?? false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            // Truncated Description with Tap to show full description
            GestureDetector(
              onTap: () {
                _showFullDescription(context, description);
              },
              child: const Text(
                'Description', // Show the literal word "Description"
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue, // Indicate it's tappable
                  decoration: TextDecoration.underline,
                ),
                // maxLines and overflow are not needed if showing a single word
              ),
            ),
          ],
        ],
      ),
    );
  }
} 