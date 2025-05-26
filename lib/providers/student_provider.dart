import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../database/database_helper.dart';

class StudentProvider with ChangeNotifier {
  List<Student> _students = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isInitialized = false;

  StudentProvider() {
    debugPrint('StudentProvider constructor called');
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('Initializing StudentProvider...');
      await loadStudents();
      _isInitialized = true;
      debugPrint('StudentProvider initialized with ${_students.length} students');
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing StudentProvider: $e');
    }
  }

  List<Student> get students {
    debugPrint('Getting students list. Initialized: $_isInitialized, Count: ${_students.length}');
    return _students;
  }

  Future<void> loadStudents() async {
    try {
      debugPrint('Loading students...');
      final loadedStudents = await _dbHelper.getAllStudents();
      debugPrint('Loaded ${loadedStudents.length} students from database');
      _students = loadedStudents;
      debugPrint('Updated _students list with ${_students.length} students');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading students: $e');
      _students = [];
      notifyListeners();
    }
  }

  Future<void> addStudent({
    required String name,
    required String fatherName,
    required String studentId,
    required String phoneNumber,
    required int age,
    required String darja,
    String? imagePath,
  }) async {
    try {
      debugPrint('Adding new student: $name');
      final student = Student(
        name: name,
        fatherName: fatherName,
        studentId: studentId,
        phoneNumber: phoneNumber,
        age: age,
        darja: darja,
        imagePath: imagePath,
      );
      final id = await _dbHelper.insertStudent(student);
      debugPrint('Student added with ID: $id');
      
      // Reload all students after adding
      await loadStudents();
      debugPrint('Students reloaded after adding. Total count: ${_students.length}');
    } catch (e) {
      debugPrint('Error adding student: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      debugPrint('Deleting student with ID: $id');
      await _dbHelper.deleteStudent(id);
      await loadStudents();
      debugPrint('Students reloaded after deletion. Total count: ${_students.length}');
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }
} 