class Performance {
  final int? id;
  final int studentId;
  final DateTime date;
  final bool sabaq;
  final bool sabqi;
  final bool manzil;
  final String? description;

  Performance({
    this.id,
    required this.studentId,
    required this.date,
    required this.sabaq,
    required this.sabqi,
    required this.manzil,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'sabaq': sabaq ? 1 : 0,
      'sabqi': sabqi ? 1 : 0,
      'manzil': manzil ? 1 : 0,
      'description': description,
    };
  }

  factory Performance.fromMap(Map<String, dynamic> map) {
    return Performance(
      id: map['id'],
      studentId: map['studentId'],
      date: DateTime.parse(map['date']),
      sabaq: map['sabaq'] == 1,
      sabqi: map['sabqi'] == 1,
      manzil: map['manzil'] == 1,
      description: map['description'],
    );
  }
} 