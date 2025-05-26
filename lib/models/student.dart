class Student {
  final int? id;
  final String name;
  final String fatherName;
  final String studentId;
  final String phoneNumber;
  final int age;
  final String darja;
  final String? imagePath;

  Student({
    this.id,
    required this.name,
    this.fatherName = '',
    this.studentId = '',
    this.phoneNumber = '',
    this.age = 0,
    this.darja = '',
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'father_name': fatherName,
      'student_id': studentId,
      'phone_number': phoneNumber,
      'age': age,
      'darja': darja,
      'image_path': imagePath,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      fatherName: map['father_name'] ?? '',
      studentId: map['student_id'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      age: map['age'] ?? 0,
      darja: map['darja'] ?? '',
      imagePath: map['image_path'],
    );
  }
} 