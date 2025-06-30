import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/student.dart';
import '../models/performance.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static const _databaseName = "Sabaq.db";
  static const _databaseVersion = 7;

  static const tableStudents = 'students';
  static const tablePerformances = 'performances';
  static const tableSections = 'sections';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableStudents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imagePath TEXT,
        sectionId INTEGER,
        fatherName TEXT NOT NULL,
        studentId TEXT,
        phoneNumber TEXT,
        FOREIGN KEY (sectionId) REFERENCES $tableSections (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE $tablePerformances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        date TEXT NOT NULL,
        sabaq INTEGER NOT NULL,
        sabqi INTEGER NOT NULL,
        manzil INTEGER NOT NULL,
        description TEXT,
        sabaqDescription TEXT,
        sabqiDescription TEXT,
        manzilDescription TEXT,
        FOREIGN KEY (studentId) REFERENCES $tableStudents (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE $tableSections (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
      
      await db.execute('ALTER TABLE $tableStudents RENAME TO temp_students');

      await db.execute('''
        CREATE TABLE $tableStudents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          age INTEGER NOT NULL,
          className TEXT NOT NULL,
          imagePath TEXT,
          sectionId INTEGER,
          FOREIGN KEY (sectionId) REFERENCES $tableSections (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('INSERT INTO $tableStudents (id, name, imagePath) SELECT id, name, image_path FROM temp_students');
      
      await db.execute('DROP TABLE temp_students');
      
      await db.execute('ALTER TABLE $tablePerformances ADD FOREIGN KEY (studentId) REFERENCES $tableStudents (id) ON DELETE CASCADE');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableStudents ADD COLUMN fatherName TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE $tableStudents ADD COLUMN studentId TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE $tableStudents ADD COLUMN phoneNumber TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE $tableStudents ADD COLUMN darja TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 4) {
      // Logic for upgrading from version 3 to 4. Remove age, darja, className
      await db.execute('CREATE TABLE temp_students AS SELECT id, name, fatherName, studentId, phoneNumber, imagePath, sectionId FROM $tableStudents');
      await db.execute('DROP TABLE $tableStudents');
      await db.execute('''
        CREATE TABLE $tableStudents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          fatherName TEXT NOT NULL,
          studentId TEXT NOT NULL,
          phoneNumber TEXT NOT NULL,
          imagePath TEXT,
          sectionId INTEGER,
          FOREIGN KEY (sectionId) REFERENCES $tableSections (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('INSERT INTO $tableStudents (id, name, fatherName, studentId, phoneNumber, imagePath, sectionId) SELECT id, name, fatherName, studentId, phoneNumber, imagePath, sectionId FROM temp_students');
      await db.execute('DROP TABLE temp_students');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE $tablePerformances ADD COLUMN sabaqDescription TEXT');
      await db.execute('ALTER TABLE $tablePerformances ADD COLUMN sabqiDescription TEXT');
      await db.execute('ALTER TABLE $tablePerformances ADD COLUMN manzilDescription TEXT');
    }
    if (oldVersion < 6) {
      // Check if the column already exists before trying to add it
      var tableInfo = await db.rawQuery('PRAGMA table_info($tablePerformances)');
      var columnExists = tableInfo.any((col) => col['name'] == 'description');
      if (!columnExists) {
        await db.execute('ALTER TABLE $tablePerformances ADD COLUMN description TEXT');
      }
    }
    if (oldVersion < 7) {
      // Recreate table to make columns nullable
      await db.execute('CREATE TABLE temp_students AS SELECT * FROM $tableStudents');
      await db.execute('DROP TABLE $tableStudents');
      await db.execute('''
        CREATE TABLE $tableStudents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          fatherName TEXT NOT NULL,
          studentId TEXT,
          phoneNumber TEXT,
          imagePath TEXT,
          sectionId INTEGER,
          FOREIGN KEY (sectionId) REFERENCES $tableSections (id) ON DELETE CASCADE
        )
      ''');
      // Copy data back, handling potential missing columns from older versions
      await db.execute('INSERT INTO $tableStudents (id, name, fatherName, studentId, phoneNumber, imagePath, sectionId) SELECT id, name, fatherName, studentId, phoneNumber, imagePath, sectionId FROM temp_students');
      await db.execute('DROP TABLE temp_students');
    }
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs}) async {
    Database db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> row, int id) async {
    Database db = await instance.database;
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // Student operations
  Future<int> insertStudent(Student student) async {
    try {
      final db = await database;
      debugPrint('Inserting student: ${student.name}');
      final id = await db.insert(tableStudents, student.toMap());
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
      final List<Map<String, dynamic>> maps = await db.query(tableStudents);
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
      tableStudents,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Performance operations
  Future<Performance> insertPerformance(Performance performance) async {
    final db = await database;
    final dayStart = DateTime(
        performance.date.year, performance.date.month, performance.date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    // Check if a record for this student and date already exists
    final List<Map<String, dynamic>> existingPerformances = await db.query(
      tablePerformances,
      where: 'studentId = ? AND date >= ? AND date < ?',
      whereArgs: [
        performance.studentId,
        dayStart.toIso8601String(),
        dayEnd.toIso8601String()
      ],
    );

    if (existingPerformances.isNotEmpty) {
      // Update the existing record
      final existingId = existingPerformances.first['id'];
      await db.update(
        tablePerformances,
        performance.toMap()..remove('id'), // Don't try to update the ID
        where: 'id = ?',
        whereArgs: [existingId],
      );
      final List<Map<String, dynamic>> maps = await db.query(
        tablePerformances,
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return Performance.fromMap(maps.first);
    } else {
      // Insert a new record
      final id = await db.insert(
          tablePerformances, performance.toMap()..remove('id'));
      // Fetch and return the inserted performance
      final List<Map<String, dynamic>> maps = await db.query(
        tablePerformances,
        where: 'id = ?',
        whereArgs: [id],
      );
      return Performance.fromMap(maps.first);
    }
  }

  Future<List<Performance>> getStudentPerformances(
      int studentId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final List<Map<String, dynamic>> maps = await db.query(
      tablePerformances,
      where: 'studentId = ? AND date >= ? AND date < ?',
      whereArgs: [
        studentId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String()
      ],
    );
    return List.generate(maps.length, (i) => Performance.fromMap(maps[i]));
  }

  Future<List<Performance>> getMonthlyPerformances(
      int studentId, DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    final List<Map<String, dynamic>> maps = await db.query(
      tablePerformances,
      where: 'studentId = ? AND date >= ? AND date < ?',
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
      tablePerformances,
      where: 'studentId IN ($studentIdsPlaceholder) AND ($dateWhereClause)',
      whereArgs: whereArgs,
    );

    return List.generate(maps.length, (i) => Performance.fromMap(maps[i]));
  }

  Future<List<Performance>> getWeeklyPerformances(
      int studentId, DateTime startDate) async {
    final db = await database;
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDate =
        startOfDay.add(const Duration(days: 7)); // Exclusive end date

    final List<Map<String, dynamic>> maps = await db.query(
      tablePerformances,
      where: 'studentId = ? AND date >= ? AND date < ?',
      whereArgs: [
        studentId,
        startOfDay.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );
    return List.generate(maps.length, (i) => Performance.fromMap(maps[i]));
  }

  Future<void> updatePerformance(Performance performance) async {
    final db = await database;
    await db.update(
      tablePerformances,
      performance.toMap(),
      where: 'id = ?',
      whereArgs: [performance.id],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  static Future<String> getDatabaseFilePath() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return path;
  }
} 