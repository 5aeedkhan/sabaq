import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/student_provider.dart';
import '../models/student.dart';
import 'daily_performance_screen.dart';
import 'add_student_screen.dart';
import 'all_students_performance_overview_screen.dart';
import 'student_details_screen.dart';
import 'login_screen.dart';
import 'dart:io'; // Import for File

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Student> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    debugPrint('StudentListScreen initState called');
    _searchController.addListener(_filterStudents);
    
    // Check authentication state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      debugPrint('Auth state changed. User: ${user?.email}');
      if (user == null && mounted) {
        debugPrint('No user found in StudentListScreen, navigating to login');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
    
    // Ensure students are loaded when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Post frame callback executing');
      if (mounted) {
        debugPrint('Loading students in post frame callback');
        context.read<StudentProvider>().loadStudents();
      }
    });
  }

  @override
  void dispose() {
    debugPrint('StudentListScreen dispose called');
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('StudentListScreen didChangeDependencies called');
    _filterStudents();
  }

  void _filterStudents() {
    final students = context.read<StudentProvider>().students;
    debugPrint('Filtering students. Total count: ${students.length}');
    
    if (_searchController.text.isEmpty) {
      _filteredStudents = students;
    } else {
      _filteredStudents = students
          .where((student) => student.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }
    debugPrint('Filtered students count: ${_filteredStudents.length}');
    
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleSearching() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes, Logout'),
            ),
          ],
        );
      },
    );

    // If user confirms logout
    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error signing out. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user found in build method, navigating to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    debugPrint('StudentListScreen build called');
    final studentsToDisplay = _isSearching ? _filteredStudents : context.watch<StudentProvider>().students;
    debugPrint('Students to display count: ${studentsToDisplay.length}');

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search Student...',
                  border: InputBorder.none,
                ),
                autofocus: true,
              )
            : const Text('Student List'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.table_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllStudentsPerformanceOverviewScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearching,
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                debugPrint('Add student button pressed');
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStudentScreen(),
                  ),
                );
                if (mounted) {
                  debugPrint('Reloading students after adding');
                  await context.read<StudentProvider>().loadStudents();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: studentsToDisplay.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No students added yet.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('Add first student button pressed');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddStudentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Student'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: studentsToDisplay.length,
              itemBuilder: (context, index) {
                final student = studentsToDisplay[index];
                debugPrint('Building list item for student: ${student.name}');
                final bool hasImage = student.imagePath != null && File(student.imagePath!).existsSync();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: hasImage ? FileImage(File(student.imagePath!)) : null,
                      child: !hasImage ? const Icon(Icons.person) : null,
                      backgroundColor: hasImage ? null : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentDetailsScreen(student: student),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            debugPrint('Delete button pressed for student: ${student.name}');
                            await context.read<StudentProvider>().deleteStudent(student.id!);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyPerformanceScreen(student: student),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
