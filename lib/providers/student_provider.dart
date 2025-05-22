import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../database/database_helper.dart';

class StudentProvider with ChangeNotifier {
  List<Student> _students = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Student> get students => _students;

  Future<void> loadStudents() async {
    _students = await _dbHelper.getAllStudents();
    notifyListeners();
  }

  Future<void> addStudent(String name) async {
    final student = Student(name: name);
    await _dbHelper.insertStudent(student);
    await loadStudents();
  }

  Future<void> deleteStudent(int id) async {
    await _dbHelper.deleteStudent(id);
    await loadStudents();
  }
} 