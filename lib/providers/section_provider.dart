import 'package:flutter/material.dart';
import '../models/section.dart';
import '../database/database_helper.dart';

class SectionProvider with ChangeNotifier {
  List<Section> _sections = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Section> get sections => _sections;

  Future<void> loadSections() async {
    final data = await _dbHelper.queryAllRows('sections');
    _sections = data.map((item) => Section.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addSection(String name) async {
    final newSection = Section(name: name);
    final id = await _dbHelper.insert('sections', newSection.toMap());
    _sections.add(Section(id: id, name: name));
    notifyListeners();
  }

  Future<void> deleteSection(int id) async {
    await _dbHelper.delete('sections', id);
    _sections.removeWhere((section) => section.id == id);
    // You might want to handle what happens to students in a deleted section.
    // For now, we'll just delete the section.
    notifyListeners();
  }
} 