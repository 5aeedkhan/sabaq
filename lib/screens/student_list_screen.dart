import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../models/student.dart';
import 'daily_performance_screen.dart';
import 'add_student_screen.dart';
import 'all_students_performance_overview_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  // Add state for search functionality
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Student> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    // Load students when the screen is initialized
    // Also add a listener to the search controller
    _searchController.addListener(_filterStudents);
    _loadStudents(); // Initial load
  }

   @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
     await context.read<StudentProvider>().loadStudents();
     // Initialize filtered list with all students after loading
     _filterStudents();
  }

  void _filterStudents() {
    final students = context.read<StudentProvider>().students;
    if (_searchController.text.isEmpty) {
      _filteredStudents = students;
    } else {
      _filteredStudents = students
          .where((student) => student.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }
    // Trigger rebuild to show filtered list
    setState(() {});
  }

  void _toggleSearching() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        // Clear search and show all students when search is closed
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the filtered students list
    final studentsToDisplay = _isSearching ? _filteredStudents : context.watch<StudentProvider>().students;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search Student...',
                  border: InputBorder.none,
                ),
                 autofocus: true, // Automatically focus the search field
              )
            : const Text('Student List'),
        actions: [
           // All Students Performance Overview Icon (only visible when not searching)
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.table_chart), // Or another suitable icon
              onPressed: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllStudentsPerformanceOverviewScreen(),
                  ),
                );
              },
            ),
          // Search icon
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearching,
          ),
          // Add student icon (only visible when not searching)
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStudentScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: studentsToDisplay.isEmpty && !_isSearching
          ? const Center(child: Text('No students added yet.'))
          : studentsToDisplay.isEmpty && _isSearching
            ? const Center(child: Text('No students found.'))
            : ListView.builder(
                itemCount: studentsToDisplay.length,
                itemBuilder: (context, index) {
                  final student = studentsToDisplay[index];
                  return ListTile(
                    title: Text(student.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => context.read<StudentProvider>().deleteStudent(student.id!), // Use context.read in event handlers
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyPerformanceScreen(student: student),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
} 