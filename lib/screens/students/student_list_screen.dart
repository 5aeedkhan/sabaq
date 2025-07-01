import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sabaq/models/section.dart';
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
import 'package:sabaq/providers/section_provider.dart';
import 'dart:ui';

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
    _studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    ); // Save reference
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

    final sectionProvider = Provider.of<SectionProvider>(context);
    final section = sectionProvider.sections.firstWhere(
      (s) => s.id == widget.sectionId,
      orElse: () => Section(id: widget.sectionId, name: 'Unknown'),
    );

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              _isSearching
                  ? Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4, right: 4),
                    child: Card(
                      key: const ValueKey('search'),
                      elevation: 6,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.18),
                          width: 1.2,
                        ),
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.98),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.search,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              autofocus: true,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                              splashRadius: 20,
                            ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : const Text(
                      'Student List',
                      key: ValueKey('title'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearching,
              tooltip: 'Search',
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          AddStudentScreen(sectionId: widget.sectionId),
                ),
              );
            },
            tooltip: 'Add Student',
          ),
        ],
      ),
      drawer: Drawer(
        child: Builder(
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.95),
                    colorScheme.secondary.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      ClipPath(
                        clipper: _DrawerWaveClipper(),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            color: colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: Row(
                          children: [
                            const SizedBox(width: 24),
                            Container(
                              margin: const EdgeInsets.only(top: 32),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  color: colorScheme.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 48.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      user.displayName ?? 'Welcome!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        shadows: [
                                          Shadow(
                                            color: colorScheme.shadow
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email ?? '',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.table_chart,
                    iconColor: colorScheme.primary,
                    title: 'All Students Performance',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AllStudentsPerformanceOverviewScreen(
                                sectionId: widget.sectionId,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerDivider(colorScheme),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.settings_backup_restore,
                    iconColor: colorScheme.secondary,
                    title: 'Backup & Restore',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BackupRestoreScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerDivider(colorScheme),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.info_outline,
                    iconColor: colorScheme.tertiary ?? Colors.teal,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      _showDeveloperInfo();
                    },
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        'IT Artificer',
                        style: TextStyle(
                          color: colorScheme.primary.withOpacity(0.7),
                          fontSize: 15,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Section: ${section.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${studentsToDisplay.length} Students',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                studentsToDisplay.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No students found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to add your first student.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: studentsToDisplay.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final student = studentsToDisplay[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading:
                                student.imagePath != null &&
                                        student.imagePath!.isNotEmpty
                                    ? CircleAvatar(
                                      radius: 26,
                                      backgroundImage: FileImage(
                                        File(student.imagePath!),
                                      ),
                                    )
                                    : CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        student.name.isNotEmpty
                                            ? student.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                            title: Text(
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              student.fatherName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'View Details',
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
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete Student',
                                  onPressed: () async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('Delete Student'),
                                            content: Text(
                                              'Are you sure you want to delete ${student.name}?',
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
                                      (context) => DailyPerformanceScreen(
                                        student: student,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: colorScheme.background.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ListTile(
            leading: Icon(icon, color: iconColor, size: 30),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: colorScheme.onBackground,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 17,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(
        color: colorScheme.primary.withOpacity(0.13),
        thickness: 1.1,
        height: 0,
      ),
    );
  }
}

class _DrawerWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
