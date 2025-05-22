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

  bool get isLoading => _isLoading;

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
    try {
      _dailyPerformances[studentId] = await _dbHelper.getStudentPerformances(studentId, date);
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMonthlyPerformances(int studentId, DateTime month) async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      _monthlyPerformances[studentId] = await _dbHelper.getMonthlyPerformances(studentId, month);
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadOverviewPerformances(List<int> studentIds, List<DateTime> dates) async {
    if (_isLoading) return;
    _isLoading = true;
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
      notifyListeners();
    } catch (e) {
      print('Error loading overview performances: $e');
      _overviewPerformances = {}; // Clear the data in case of error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWeeklyPerformances(int studentId, DateTime startDate) async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      _weeklyPerformances[studentId] = await _dbHelper.getWeeklyPerformances(studentId, startDate);
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<Performance> addPerformance(Performance performance) async {
    if (_isLoading) return performance;
    _isLoading = true;
    try {
      final savedPerformance = await _dbHelper.insertPerformance(performance);
      
      // Update daily performances
      if (_dailyPerformances.containsKey(savedPerformance.studentId)) {
        _dailyPerformances[savedPerformance.studentId]!.add(savedPerformance);
        _dailyPerformances[savedPerformance.studentId]!.removeWhere((p) => 
          p.id != savedPerformance.id && 
          DateFormat('yyyy-MM-dd').format(p.date) == DateFormat('yyyy-MM-dd').format(savedPerformance.date)
        );
      }

      // Update monthly performances
      if (_monthlyPerformances.containsKey(savedPerformance.studentId)) {
        _monthlyPerformances[savedPerformance.studentId]!.add(savedPerformance);
        _monthlyPerformances[savedPerformance.studentId]!.removeWhere((p) => 
          p.id != savedPerformance.id && 
          DateFormat('yyyy-MM-dd').format(p.date) == DateFormat('yyyy-MM-dd').format(savedPerformance.date)
        );
      }

      // Update overview performances with the savedPerformance
      if (!_overviewPerformances.containsKey(savedPerformance.studentId)) {
        _overviewPerformances[savedPerformance.studentId] = {};
      }
      _overviewPerformances[savedPerformance.studentId]![DateFormat('yyyy-MM-dd').format(savedPerformance.date)] = savedPerformance;

      print('DEBUG: PerformanceProvider - addPerformance finished. Updated overview map for student ${savedPerformance.studentId}, date ${DateFormat('yyyy-MM-dd').format(savedPerformance.date)}. Map entry exists: ${_overviewPerformances[savedPerformance.studentId]?.containsKey(DateFormat('yyyy-MM-dd').format(savedPerformance.date))}');

      notifyListeners();
      return savedPerformance;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updatePerformance(Performance performance) async {
    if (_isLoading) return;
    _isLoading = true;
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

      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }
} 