class Reservation {
  final String id;
  final String userId;
  final String spaceId;
  final DateTime startTime;
  final DateTime endTime;
  final double amount;

  Reservation(
      {required this.id,
      required this.userId,
      required this.spaceId,
      required this.startTime,
      required this.endTime,
      required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'space_id': spaceId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'amount': amount,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      userId: map['user_id'],
      spaceId: map['space_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      amount: map['amount'],
    );
  }
}
