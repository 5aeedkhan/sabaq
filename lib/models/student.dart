class Student {
  final int? id;
  final String name;
  final String fatherName;
  final String studentId;
  final String phoneNumber;
  final String? imagePath;
  final int sectionId;

  Student({
    this.id,
    required this.name,
    required this.fatherName,
    required this.studentId,
    required this.phoneNumber,
    this.imagePath,
    required this.sectionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fatherName': fatherName,
      'studentId': studentId,
      'phoneNumber': phoneNumber,
      'imagePath': imagePath,
      'sectionId': sectionId,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      fatherName: map['fatherName'] ?? '',
      studentId: map['studentId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      imagePath: map['imagePath'],
      sectionId: map['sectionId'],
    );
  }
} 