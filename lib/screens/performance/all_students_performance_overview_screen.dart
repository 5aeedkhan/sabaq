import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sabaq/models/performance.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/providers/performance_provider.dart';
import 'package:sabaq/providers/student_provider.dart';
import 'package:marquee/marquee.dart';

enum PerformanceViewType { recent, single }

class AllStudentsPerformanceOverviewScreen extends StatefulWidget {
  final int sectionId;
  const AllStudentsPerformanceOverviewScreen(
      {super.key, required this.sectionId});

  @override
  State<AllStudentsPerformanceOverviewScreen> createState() =>
      _AllStudentsPerformanceOverviewScreenState();
}

class _AllStudentsPerformanceOverviewScreenState
    extends State<AllStudentsPerformanceOverviewScreen> {
  List<Student> _students = [];
  List<DateTime> _datesToDisplay = [];
  bool _isLoading = true;
  PerformanceViewType _viewType = PerformanceViewType.recent;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingOverlay = false;

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoadingOverlay = true;
      });
      await _loadData();
      setState(() {
        _isLoadingOverlay = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load students for the specific section
      final studentProvider = context.read<StudentProvider>();
      await studentProvider.loadStudents(widget.sectionId);

      if (!mounted) return;

      // Access students from the provider after loading
      _students = studentProvider.students;

      if (_viewType == PerformanceViewType.recent) {
        _datesToDisplay = List.generate(5, (index) {
          return DateTime.now().subtract(Duration(days: index));
        }).reversed.toList();
      } else {
        _datesToDisplay = [_selectedDate];
      }

      // Load performance for each student for each of the recent dates
      if (_students.isNotEmpty && _datesToDisplay.isNotEmpty) {
        await context.read<PerformanceProvider>().loadOverviewPerformances(
          _students.map((s) => s.id!).toList(),
          _datesToDisplay,
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
  Performance? _getPerformance(
    BuildContext context,
    int studentId,
    DateTime date,
  ) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    // Read directly from the provider's state
    final performancesForStudent =
        context.watch<PerformanceProvider>().overviewPerformances[studentId];
    return performancesForStudent?[dateString];
  }

  // Helper to update performance for a specific student and date
  Future<void> _updatePerformance({
    required Student student,
    required DateTime date,
    bool? sabaq,
    bool? sabqi,
    bool? manzil,
    String? sabaqDescription,
    String? sabqiDescription,
    String? manzilDescription,
  }) async {
    // Read existing performance directly from the provider state
    Performance? existingPerformance =
        context.read<PerformanceProvider>().overviewPerformances[student
            .id!]?[DateFormat('yyyy-MM-dd').format(date)];

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
        sabaqDescription: sabaqDescription ?? existingPerformance.sabaqDescription,
        sabqiDescription: sabqiDescription ?? existingPerformance.sabqiDescription,
        manzilDescription: manzilDescription ?? existingPerformance.manzilDescription,
      );
    } else {
      // Create new performance - DO NOT provide an ID.
      newPerformance = Performance(
        studentId: student.id!,
        date: date,
        sabaq: sabaq ?? false,
        sabqi: sabqi ?? false,
        manzil: manzil ?? false,
        sabaqDescription: sabaqDescription,
        sabqiDescription: sabqiDescription,
        manzilDescription: manzilDescription,
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
  void _showFullDescription(BuildContext context, String generalDescription, String sabaqDescription, String sabqiDescription, String manzilDescription) {
    final List<String> notes = [];
    if (generalDescription.isNotEmpty) {
      notes.add('General: $generalDescription');
    }
    if (sabaqDescription.isNotEmpty) {
      notes.add('Sabaq: $sabaqDescription');
    }
    if (sabqiDescription.isNotEmpty) {
      notes.add('Sabqi: $sabqiDescription');
    }
    if (manzilDescription.isNotEmpty) {
      notes.add('Manzil: $manzilDescription');
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Full Description'),
          content: SingleChildScrollView(child: Text(notes.join('\n\n'))),
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

  void _showEditDescriptionDialog(
    BuildContext context,
    Student student,
    DateTime date,
    String performanceType, // 'S', 'Sb', or 'M'
    String initialDescription,
  ) {
    final TextEditingController controller =
        TextEditingController(text: initialDescription);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Description for $performanceType'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final newDescription = controller.text.trim();
                if (performanceType == 'S') {
                  _updatePerformance(
                    student: student,
                    date: date,
                    sabaqDescription: newDescription,
                  );
                } else if (performanceType == 'Sb') {
                  _updatePerformance(
                    student: student,
                    date: date,
                    sabqiDescription: newDescription,
                  );
                } else if (performanceType == 'M') {
                  _updatePerformance(
                    student: student,
                    date: date,
                    manzilDescription: newDescription,
                  );
                }
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
        title: SizedBox(
          height: 24,
          child: Marquee(
            text: 'Students Performance Overview',
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
          if (_viewType == PerformanceViewType.single)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ToggleButtons(
              isSelected: [
                _viewType == PerformanceViewType.recent,
                _viewType == PerformanceViewType.single,
              ],
              onPressed: _isLoading || _isLoadingOverlay
                  ? null
                  : (index) async {
                      if ((_viewType == PerformanceViewType.recent && index == 0) ||
                          (_viewType == PerformanceViewType.single && index == 1)) {
                        return;
                      }
                      setState(() {
                        _viewType = index == 0
                            ? PerformanceViewType.recent
                            : PerformanceViewType.single;
                        _isLoadingOverlay = true;
                      });
                      await _loadData();
                      setState(() {
                        _isLoadingOverlay = false;
                      });
                    },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              color: Colors.white.withOpacity(0.7),
              fillColor: Colors.blue.withOpacity(0.5),
              splashColor: Colors.blue.shade900,
              highlightColor: Colors.blue.shade800,
              constraints: const BoxConstraints(minHeight: 36.0),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Recent'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('By Day'),
                ),
              ],
            ),
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
                        for (var date in _datesToDisplay)
                          DataColumn(
                            label: Text(DateFormat('d-MMM').format(date)),
                          ),
                      ],
                      rows: [
                        for (var student in _students)
                          DataRow(
                            cells: [
                              DataCell(Text(student.name)),
                              for (var date in _datesToDisplay)
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

  Widget _buildPerformanceCell(
    BuildContext context,
    Student student,
    DateTime date,
  ) {
    final performance = _getPerformance(context, student.id!, date);
    final bool sabaq = performance?.sabaq ?? false;
    final bool sabqi = performance?.sabqi ?? false;
    final bool manzil = performance?.manzil ?? false;
    final String description = performance?.description ?? '';
    final String sabaqDescription = performance?.sabaqDescription ?? '';
    final String sabqiDescription = performance?.sabqiDescription ?? '';
    final String manzilDescription = performance?.manzilDescription ?? '';

    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPerformanceItem(
            context,
            student,
            date,
            'S',
            sabaq,
            sabaqDescription.isNotEmpty ? sabaqDescription : description,
          ),
          const SizedBox(width: 8),
          _buildPerformanceItem(
            context,
            student,
            date,
            'Sb',
            sabqi,
            sabqiDescription.isNotEmpty ? sabqiDescription : description,
          ),
          const SizedBox(width: 8),
          _buildPerformanceItem(
            context,
            student,
            date,
            'M',
            manzil,
            manzilDescription.isNotEmpty ? manzilDescription : description,
          ),
          if (description.isNotEmpty ||
              sabaqDescription.isNotEmpty ||
              sabqiDescription.isNotEmpty ||
              manzilDescription.isNotEmpty) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                _showFullDescription(context, description, sabaqDescription,
                    sabqiDescription, manzilDescription);
              },
              child: Text(
                'View\nNotes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue.shade700,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(
    BuildContext context,
    Student student,
    DateTime date,
    String label,
    bool value,
    String description,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Checkbox(
          visualDensity: VisualDensity.compact,
          value: value,
          onChanged: (bool? newValue) async {
            if (label == 'S') {
              await _updatePerformance(
                  student: student, date: date, sabaq: newValue);
            } else if (label == 'Sb') {
              await _updatePerformance(
                  student: student, date: date, sabqi: newValue);
            } else if (label == 'M') {
              await _updatePerformance(
                  student: student, date: date, manzil: newValue);
            }
          },
        ),
        GestureDetector(
          onTap: () {
            _showEditDescriptionDialog(
                context, student, date, label, description);
          },
          child: Text(
            'Edit',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade700,
              decoration: TextDecoration.underline,
              decorationColor: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
