class ParkingSpace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final double price;

  ParkingSpace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'price': price,
    };
  }

  factory ParkingSpace.fromMap(Map<String, dynamic> map) {
    return ParkingSpace(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isAvailable: map['isAvailable'],
      price: map['price'],
    );
  }
}
