import 'package:flutter/foundation.dart';
import '../models/performance.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

class PerformanceProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<int, List<Performance>> _dailyPerformances = {};
  Map<int, List<Performance>> _monthlyPerformances = {};
  Map<int, Map<String, Performance>> _overviewPerformances = {};
  Map<int, List<Performance>> _weeklyPerformances = {};
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Performance> getDailyPerformances(int studentId, DateTime date) {
    return _dailyPerformances[studentId] ?? [];
  }

  List<Performance> getMonthlyPerformances(int studentId, DateTime month) {
    return _monthlyPerformances[studentId] ?? [];
  }

  Map<int, Map<String, Performance>> get overviewPerformances => _overviewPerformances;

  List<Performance> getWeeklyPerformances(int studentId) {
    return _weeklyPerformances[studentId] ?? [];
  }

  Future<void> loadDailyPerformances(int studentId, DateTime date) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(notifyListeners);

    try {
      _dailyPerformances[studentId] = await _dbHelper.getStudentPerformances(studentId, date);
    } catch (e) {
      _errorMessage = 'Failed to load daily performance. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyPerformances(int studentId, DateTime month) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(notifyListeners);

    try {
      _monthlyPerformances[studentId] = await _dbHelper.getMonthlyPerformances(studentId, month);
    } catch (e) {
      _errorMessage = 'Failed to load monthly performance. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOverviewPerformances(List<int> studentIds, List<DateTime> dates) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(notifyListeners);

    try {
      final performances = await _dbHelper.getPerformancesForStudentsAndDates(studentIds, dates);
      _overviewPerformances = {};
      for (var performance in performances) {
        if (!_overviewPerformances.containsKey(performance.studentId)) {
          _overviewPerformances[performance.studentId] = {};
        }
        _overviewPerformances[performance.studentId]![DateFormat('yyyy-MM-dd').format(performance.date)] = performance;
      }
      print('DEBUG: PerformanceProvider - loadOverviewPerformances finished. Overview map size: ${_overviewPerformances.length}');
    } catch (e) {
      _errorMessage = 'Failed to load performance overview. Please try again.';
      _overviewPerformances = {}; // Clear the data in case of error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWeeklyPerformances(int studentId, DateTime startDate) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(notifyListeners);

    try {
      _weeklyPerformances[studentId] = await _dbHelper.getWeeklyPerformances(studentId, startDate);
    } catch (e) {
      _errorMessage = 'Failed to load weekly performance. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Performance> addPerformance(Performance performance) async {
    if (_isLoading) return performance;
    _isLoading = true;
    notifyListeners();

    try {
      final savedPerformance = await _dbHelper.insertPerformance(performance);
      
      // Update daily performances
      if (_dailyPerformances.containsKey(savedPerformance.studentId)) {
        _dailyPerformances[savedPerformance.studentId]!.removeWhere((p) => 
          p.date.year == savedPerformance.date.year &&
          p.date.month == savedPerformance.date.month &&
          p.date.day == savedPerformance.date.day);
        _dailyPerformances[savedPerformance.studentId]!.add(savedPerformance);
      }

      // Update monthly performances
      if (_monthlyPerformances.containsKey(savedPerformance.studentId)) {
        _monthlyPerformances[savedPerformance.studentId]!.removeWhere((p) => 
          p.date.year == savedPerformance.date.year &&
          p.date.month == savedPerformance.date.month &&
          p.date.day == savedPerformance.date.day);
        _monthlyPerformances[savedPerformance.studentId]!.add(savedPerformance);
      }

      // Update overview performances
      if (!_overviewPerformances.containsKey(savedPerformance.studentId)) {
        _overviewPerformances[savedPerformance.studentId] = {};
      }
      _overviewPerformances[savedPerformance.studentId]![DateFormat('yyyy-MM-dd').format(savedPerformance.date)] = savedPerformance;

      print('DEBUG: PerformanceProvider - addPerformance finished. Updated overview map for student ${savedPerformance.studentId}, date ${DateFormat('yyyy-MM-dd').format(savedPerformance.date)}. Map entry exists: ${_overviewPerformances[savedPerformance.studentId]?.containsKey(DateFormat('yyyy-MM-dd').format(savedPerformance.date))}');

      notifyListeners();
      return savedPerformance;
    } catch (e) {
      _errorMessage = 'Failed to save performance.';
      notifyListeners();
      return performance;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updatePerformance(Performance performance) async {
    if (_isLoading) return;
    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      await _dbHelper.updatePerformance(performance);
      
      // Update overview performances
      if (_overviewPerformances.containsKey(performance.studentId)) {
        _overviewPerformances[performance.studentId]![DateFormat('yyyy-MM-dd').format(performance.date)] = performance;
      }

      // Update daily performances
      if (_dailyPerformances.containsKey(performance.studentId)) {
        final index = _dailyPerformances[performance.studentId]!.indexWhere((p) => p.id == performance.id);
        if (index != -1) {
          _dailyPerformances[performance.studentId]![index] = performance;
        }
      }

      // Update monthly performances
      if (_monthlyPerformances.containsKey(performance.studentId)) {
        final index = _monthlyPerformances[performance.studentId]!.indexWhere((p) => p.id == performance.id);
        if (index != -1) {
          _monthlyPerformances[performance.studentId]![index] = performance;
        }
      }

      // Update weekly performances
      if (_weeklyPerformances.containsKey(performance.studentId)) {
        final index = _weeklyPerformances[performance.studentId]!.indexWhere((p) => p.id == performance.id);
        if (index != -1) {
          _weeklyPerformances[performance.studentId]![index] = performance;
        }
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update performance.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 