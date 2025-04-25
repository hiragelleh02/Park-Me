import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchGarageInfoFromAPI(
    String name, String placeId) async {
  const apiKey = 'AIzaSyDaa-KNS7PvWNB1_MIbmmGcVmsFMbHBonA';
  final url = 'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId&fields=name,formatted_address,opening_hours,rating,user_ratings_total,price_level'
      '&key=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final result = data['result'];

    return {
      'name': result['name'],
      'address': result['formatted_address'],
      'open_hours':
          result['opening_hours']?['weekday_text']?.join(', ') ?? 'N/A',
      'rating': result['rating']?.toString() ?? 'N/A',
      'total_ratings': result['user_ratings_total']?.toString() ?? 'N/A',
      'price_level': result['price_level']?.toString() ?? 'N/A',
      'place_id': placeId,
    };
  } else {
    throw Exception('Failed to fetch garage details');
  }
}
