import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class ParkingApiService {
  final String apiKey = "AIzaSyDaa-KNS7PvWNB1_MIbmmGcVmsFMbHBonA";

  Future<List<Map<String, dynamic>>> getNearbyParking() async {
    Position position = await Geolocator.getCurrentPosition();
    String url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=${position.latitude},${position.longitude}"
        "&radius=2000&type=parking&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results']
          .map<Map<String, dynamic>>((place) => {
                'name': place['name'],
                'location': place['geometry']['location'],
                'place_id': place['place_id'],
              })
          .toList();
    } else {
      throw Exception("Failed to load parking spaces");
    }
  }
}
