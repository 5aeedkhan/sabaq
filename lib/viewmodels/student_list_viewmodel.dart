import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../providers/student_provider.dart'; // We will likely refactor this later

class StudentListViewModel with ChangeNotifier {
  final StudentProvider _studentProvider; // ViewModel will interact with a data source

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = false;

  StudentListViewModel(this._studentProvider) {
    debugPrint('StudentListViewModel created');
    _loadStudents(); // Load students when the ViewModel is created
  }

  List<Student> get students => _filteredStudents; // Expose filtered list to UI
  bool get isLoading => _isLoading;

  Future<void> _loadStudents() async {
    debugPrint('ViewModel loading students...');
    _isLoading = true;
    notifyListeners();

    try {
      await _studentProvider.loadStudents('yourArgumentHere' as int); // Load students (assumed to populate a property)
      _allStudents = _studentProvider.students; // Access the loaded students from the provider
      _filteredStudents = _allStudents; // Initially show all students
      debugPrint('ViewModel loaded ${_allStudents.length} students.');
    } catch (e) {
      debugPrint('ViewModel Error loading students: $e');
      // Handle error, maybe set an error state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterStudents(String query) {
    debugPrint('ViewModel filtering students with query: $query');
    if (query.isEmpty) {
      _filteredStudents = _allStudents;
    } else {
      _filteredStudents = _allStudents
          .where((student) => student.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    debugPrint('ViewModel filtered students count: ${_filteredStudents.length}');
    notifyListeners();
  }

  // We might add methods for deleting students here later
} 