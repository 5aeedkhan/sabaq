import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../providers/student_provider.dart'; // We will likely refactor this later

class AddStudentViewModel with ChangeNotifier {
  final StudentProvider _studentProvider; // ViewModel will interact with a data source

  AddStudentViewModel(this._studentProvider) {
    debugPrint('AddStudentViewModel created');
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
    debugPrint('ViewModel adding student: $name');
    try {
      // Basic validation (can be expanded)
      if (name.isEmpty || fatherName.isEmpty || studentId.isEmpty || phoneNumber.isEmpty || darja.isEmpty) {
         throw Exception('Please fill in all required fields.');
      }
       if (age <= 0) {
         throw Exception('Please enter a valid age.');
       }

      final student = Student(
        name: name,
        fatherName: fatherName,
        studentId: studentId,
        phoneNumber: phoneNumber,
        age: age,
        darja: darja,
        imagePath: imagePath,
      );

      await _studentProvider.addStudent( // Assuming addStudent handles insertion and reloading
        name: student.name,
        fatherName: student.fatherName,
        studentId: student.studentId,
        phoneNumber: student.phoneNumber,
        age: student.age,
        darja: student.darja,
        imagePath: student.imagePath,
      );
      debugPrint('ViewModel student added successfully');
    } catch (e) {
      debugPrint('ViewModel Error adding student: $e');
      rethrow; // Rethrow the exception for the UI to handle
    }
  }

  // We might add methods for form state management here later
} 