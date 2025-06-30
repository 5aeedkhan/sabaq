import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sabaq/models/student.dart';
import 'package:sabaq/providers/student_provider.dart';
import '../performance/daily_performance_screen.dart';
import './add_student_screen.dart';
import '../performance/all_students_performance_overview_screen.dart';
import './student_details_screen.dart';
import '../auth/login_screen.dart';
import '../settings/backup_restore_screen.dart';
import 'dart:io'; // Import for File
import 'package:url_launcher/url_launcher.dart';
import 'package:marquee/marquee.dart';

class StudentListScreen extends StatefulWidget {
  final int sectionId;
  const StudentListScreen({super.key, required this.sectionId});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Student> _filteredStudents = [];
  StudentProvider? _studentProvider; // Save provider reference

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
        context.read<StudentProvider>().loadStudents(widget.sectionId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('StudentListScreen didChangeDependencies called');
    _studentProvider = Provider.of<StudentProvider>(context, listen: false); // Save reference
    _filterStudents();
  }

  @override
  void dispose() {
    // Use the saved provider reference and prevent UI notifications on clear
    _studentProvider?.clearStudents(notify: false); 
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final students = context.read<StudentProvider>().students;
    debugPrint('Filtering students. Total count: ${students.length}');

    if (_searchController.text.isEmpty) {
      _filteredStudents = students;
    } else {
      _filteredStudents =
          students
              .where(
                (student) => student.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
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

  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Center(
            child: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircleAvatar(
                radius: 40,
                // You can add an image here if you have one
                // backgroundImage: AssetImage('assets/your_image.png'),
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Muhammad Saeed Khan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mobile Application Developer',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'at IT Artificer',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _launchURL('https://portfolio-c4b78.web.app/'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A simple representation of LinkedIn icon
                    Text(
                      'Portfolio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 20,
                      ),
                    ),
                    // SizedBox(width: 8),
                    // Text(
                    //   'Portfolio',
                    //   style: TextStyle(
                    //     color: Colors.blue,
                    //     decoration: TextDecoration.underline,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
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

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    debugPrint('StudentListScreen build called');
    final studentsToDisplay =
        _isSearching
            ? _filteredStudents
            : context.watch<StudentProvider>().students;
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
            : SizedBox(
                height: 24,
                child: Marquee(
                  text: 'Student List',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace: 40.0,
                  velocity: 30.0,
                  pauseAfterRound: Duration(seconds: 1),
                  startPadding: 10.0,
                  accelerationDuration: Duration(seconds: 1),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.table_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AllStudentsPerformanceOverviewScreen(
                            sectionId: widget.sectionId),
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
                    builder: (context) => AddStudentScreen(sectionId: widget.sectionId),
                  ),
                );
                if (mounted) {
                  debugPrint('Reloading students after adding');
                  await context.read<StudentProvider>().loadStudents(widget.sectionId);
                }
              },
            ),
          if (!_isSearching)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupRestoreScreen(),
                    ),
                  );
                } else if (value == 'info') {
                  _showDeveloperInfo();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'info',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('About'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body:
          studentsToDisplay.isEmpty
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
                              builder: (context) => AddStudentScreen(sectionId: widget.sectionId),
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
                    debugPrint(
                      'Building list item for student: ${student.name}',
                    );
                    final bool hasImage =
                        student.imagePath != null &&
                        File(student.imagePath!).existsSync();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              hasImage
                                  ? FileImage(File(student.imagePath!))
                                  : null,
                          child: !hasImage ? const Icon(Icons.person) : null,
                          backgroundColor:
                              hasImage
                                  ? null
                                  : Theme.of(context).colorScheme.primary,
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
                                    builder:
                                        (context) => StudentDetailsScreen(
                                          student: student,
                                        ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Delete Student'),
                                        content: Text(
                                          'Are you sure you want to delete \\${student.name}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                );
                                if (shouldDelete == true) {
                                  debugPrint(
                                    'Delete button pressed for student: \\${student.name}',
                                  );
                                  await context
                                      .read<StudentProvider>()
                                      .deleteStudent(student.id!);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      DailyPerformanceScreen(student: student),
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
