import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/performance.dart';
// Import a service/repository class later for data fetching and saving

class DailyPerformanceViewModel with ChangeNotifier {
  final Student _student;
  // Data for the UI
  DateTime _selectedDate = DateTime.now();
  bool _sabaq = false;
  bool _sabqi = false;
  bool _manzil = false;
  String _description = '';
  File? _selectedImage; // Assuming we handle image path here

  // State for UI feedback
  bool _isLoading = false;
  String? _errorMessage;

  // Getters for UI to consume
  Student get student => _student;
  DateTime get selectedDate => _selectedDate;
  bool get sabaq => _sabaq;
  bool get sabqi => _sabqi;
  bool get manzil => _manzil;
  String get description => _description;
  File? get selectedImage => _selectedImage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DailyPerformanceViewModel(this._student) {
    debugPrint('DailyPerformanceViewModel created for student: ${_student.name}');
    _loadPerformance(); // Load initial performance data
  }

  // Methods for UI to interact with
  void updateSabaq(bool value) {
    _sabaq = value;
    notifyListeners();
  }

  void updateSabqi(bool value) {
    _sabqi = value;
    notifyListeners();
  }

  void updateManzil(bool value) {
    _manzil = value;
    notifyListeners();
  }

  void updateDescription(String value) {
    _description = value;
    notifyListeners();
  }

   void updateSelectedImage(File? imageFile) {
    _selectedImage = imageFile;
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      notifyListeners();
      await _loadPerformance(); // Load performance for the newly selected date
    }
  }

  Future<void> _loadPerformance() async {
    debugPrint('ViewModel loading performance for date: $_selectedDate');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual service call to load performance for student and date
      // For now, simulate loading:
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network/db call
      // Assume this fetches a Performance object or null
      final Performance? performance = null; // Replace with actual loaded data

      // Example of setting state based on loaded performance:
      /* // Commented out to prevent null access error during refactoring
      if (performance != null) {
        _sabaq = performance.sabaq;
        _sabqi = performance.sabqi;
        _manzil = performance.manzil;
        _description = performance.description ?? '';
        _selectedImage = performance.imagePath != null ? File(performance.imagePath!) : null;
        debugPrint('ViewModel loaded performance data.');
      } else {
        // Clear state if no performance found
        _sabaq = false;
        _sabqi = false;
        _manzil = false;
        _description = '';
        _selectedImage = null;
        debugPrint('ViewModel no performance data found.');
      }
      */
      // Since loading is not implemented, explicitly clear state for the current date
       _sabaq = false;
       _sabqi = false;
       _manzil = false;
       _description = '';
       _selectedImage = null;
       debugPrint('ViewModel performance state cleared (loading not implemented).');

    } catch (e) {
      debugPrint('ViewModel Error loading performance: $e');
      _errorMessage = 'Failed to load performance.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePerformance() async {
    debugPrint('ViewModel saving performance for date: $_selectedDate');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Basic validation before saving
      // if (_description.trim().isEmpty && !_sabaq && !_sabqi && !_manzil && _selectedImage == null) {
      //   _errorMessage = 'Please enter some performance data or select an image.';
      //   notifyListeners();
      //   return false;
      // }

      final performance = Performance(
        studentId: _student.id!,
        date: _selectedDate,
        sabaq: _sabaq,
        sabqi: _sabqi,
        manzil: _manzil,
        description: _description.trim().isEmpty ? null : _description.trim(),
        imagePath: _selectedImage?.path,
      );

      // TODO: Replace with actual service call to save performance
      // await _performanceService.savePerformance(performance);
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate saving delay

      debugPrint('ViewModel performance saved successfully.');
      return true;

    } catch (e) {
      debugPrint('ViewModel Error saving performance: $e');
      _errorMessage = 'Failed to save performance.';
      notifyListeners();
      return false;
    }
  }

  // We might add methods for fetching weekly/monthly performance here later
} 