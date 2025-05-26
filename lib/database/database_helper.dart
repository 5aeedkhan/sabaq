import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/performance.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    debugPrint('Initializing database...');
    _database = await _initDB('sabaq.db');
    debugPrint('Database initialized successfully');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('Database path: $path');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    debugPrint('Creating database tables...');
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        father_name TEXT,
        student_id TEXT,
        phone_number TEXT,
        age INTEGER,
        darja TEXT,
        image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE performances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        date TEXT NOT NULL,
        sabaq INTEGER NOT NULL,
        sabqi INTEGER NOT NULL,
        manzil INTEGER NOT NULL,
        description TEXT,
        FOREIGN KEY (studentId) REFERENCES students (id)
      )
    ''');
    debugPrint('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE performances ADD COLUMN description TEXT;');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE students ADD COLUMN image_path TEXT;');
    }
    debugPrint('Database upgrade completed');
  }

  // Student operations
  Future<int> insertStudent(Student student) async {
    try {
      final db = await database;
      debugPrint('Inserting student: ${student.name}');
      final id = await db.insert('students', student.toMap());
      debugPrint('Student inserted with id: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting student: $e');
      rethrow;
    }
  }

  Future<List<Student>> getAllStudents() async {
    try {
      final db = await database;
      debugPrint('Fetching all students...');
      final List<Map<String, dynamic>> maps = await db.query('students');
      final students = List.generate(maps.length, (i) => Student.fromMap(maps[i]));
      debugPrint('Fetched ${students.length} students');
      return students;
    } catch (e) {
      debugPrint('Error fetching students: $e');
      rethrow;
    }
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Performance operations
  Future<Performance> insertPerformance(Performance performance) async {
    final db = await database;
    // Check if a record for this student and date already exists
    final existingPerformance = await db.query(
      'performances',
      where: 'studentId = ? AND date = ?',
      whereArgs: [performance.studentId, performance.date.toIso8601String()],
    );

    if (existingPerformance.isNotEmpty) {
      // Update the existing record
      final updatedRows = await db.update(
        'performances',
        performance.toMap(),
        where: 'studentId = ? AND date = ?',
        whereArgs: [performance.studentId, performance.date.toIso8601String()],
      );
      // Fetch and return the updated performance
      final List<Map<String, dynamic>> maps = await db.query(
        'performances',
        where: 'id = ?',
        whereArgs: [existingPerformance.first['id']],
      );
      return Performance.fromMap(maps.first);

    } else {
      // Insert a new record
      final id = await db.insert('performances', performance.toMap());
      // Fetch and return the inserted performance
       final List<Map<String, dynamic>> maps = await db.query(
        'performances',
        where: 'id = ?',
        whereArgs: [id],
      );
      return Performance.fromMap(maps.first);
    }
  }

  Future<List<Performance>> getStudentPerformances(int studentId, DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'performances',
      where: 'studentId = ? AND date = ?',
      whereArgs: [studentId, date.toIso8601String()],
    );
    return List.generate(maps.length, (i) => Performance.fromMap(maps[i]));
  }

  Future<List<Performance>> getMonthlyPerformances(int studentId, DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'performances',
      where: 'studentId = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        studentId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );
    return List.generate(maps.length, (i) => Performance.fromMap(maps[i]));
  }

  Future<List<Performance>> getPerformancesForStudentsAndDates(List<int> studentIds, List<DateTime> dates) async {
    if (studentIds.isEmpty || dates.isEmpty) {
      return [];
    }

    final db = await database;
    
    // Create a list of date ranges (start of day to end of day) for querying
    final List<String> dateQueries = [];
    final List<dynamic> whereArgs = [...studentIds];

    final String studentIdsPlaceholder = List.generate(studentIds.length, (_) => '?').join(',');
    String dateWhereClause = '';

    for (var date in dates) {
        final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0).toIso8601String();
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).toIso8601String();
        dateQueries.add('(date BETWEEN ? AND ?)');
        whereArgs.add(startOfDay);
        whereArgs.add(endOfDay);
    }
    
    dateWhereClause = dateQueries.join(' OR ');

    final List<Map<String, dynamic>> maps = await db.query(
      'performances',
      where: 'studentId IN ($studentIdsPlaceholder) AND ($dateWhereClause)',
      whereArgs: whereArgs,
    );

    return List.generate(maps.length, (i) => Performance.fromMap(maps[i]));
  }

  Future<List<Performance>> getWeeklyPerformances(int studentId, DateTime startDate) async {
    final db = await database;
    final endDate = startDate.add(const Duration(days: 6)); // Get 7 days including the start date
    
    final List<Map<String, dynamic>> maps = await db.query(
      'performances',
      where: 'studentId = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        studentId,
        DateFormat('yyyy-MM-dd').format(startDate),
        DateFormat('yyyy-MM-dd').format(endDate),
      ],
    );
    return List.generate(maps.length, (i) => Performance.fromMap(maps[i]));
  }

  Future<void> updatePerformance(Performance performance) async {
    final db = await database;
    await db.update(
      'performances',
      performance.toMap(),
      where: 'id = ?',
      whereArgs: [performance.id],
    );
  }
} 