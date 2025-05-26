import 'package:flutter/foundation.dart';
import '../models/student.dart';
// Import a service/repository class later for data fetching

class StudentDetailsViewModel with ChangeNotifier {
  Student? _student;
  bool _isLoading = false;
  String? _errorMessage;

  Student? get student => _student;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor might take a student ID or the student object directly
  // For now, let's assume it takes the student object
  StudentDetailsViewModel(Student student) {
    debugPrint('StudentDetailsViewModel created for student: ${student.name}');
    _student = student; // Initialize with the provided student
    // In a real scenario, you might fetch the full student details here
    notifyListeners();
  }

  // We could add methods here for editing student details later
} 