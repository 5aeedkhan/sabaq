import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../database/database_helper.dart';

class StudentProvider with ChangeNotifier {
  List<Student> _students = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isInitialized = false;

  StudentProvider() {
    debugPrint('StudentProvider created');
  }

  List<Student> get students => _students;

  Future<void> loadAllStudents() async {
    final data = await _dbHelper.query('students');
    _students = data.map((item) => Student.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> loadStudents(int sectionId) async {
    final data = await _dbHelper.query(
      'students',
      where: 'sectionId = ?',
      whereArgs: [sectionId],
    );
    _students = data.map((item) => Student.fromMap(item)).toList();
    notifyListeners();
  }

  void clearStudents({bool notify = true}) {
    _students = [];
    if (notify) {
    notifyListeners();
    }
  }

  Future<void> addStudent(Student student) async {
    final id = await _dbHelper.insert('students', student.toMap());
    final newStudent = Student(
      id: id,
      name: student.name,
      fatherName: student.fatherName,
      studentId: student.studentId,
      phoneNumber: student.phoneNumber,
      imagePath: student.imagePath,
      sectionId: student.sectionId,
    );
    _students.add(newStudent);
    notifyListeners();
  }

  Future<void> updateStudent(Student student) async {
    await _dbHelper.update('students', student.toMap(), student.id!);
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(int id) async {
    await _dbHelper.delete('students', id);
    _students.removeWhere((student) => student.id == id);
    notifyListeners();
  }
}
