Future<Map<String, dynamic>> fetchGarageInfoFromAPI(
    String name, String placeId) async {
  // Simulated response – replace with real API later
  return {
    'name': name,
    'address': "123 ${name.split(' ').first} St",
    'hourly_rate': 3.50,
    'available_spots': 12,
    'open_hours': "6AM - 10PM",
    'has_ev_charging': true,
    'place_id': placeId,
  };
}
