import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/firestore_service.dart';
import '../widgets/garage_details_bottom_sheet.dart';
import '../screens/reservation_screen.dart';

class ParkingScreen extends StatefulWidget {
  @override
  _ParkingScreenState createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  late GoogleMapController _mapController;
  List<Marker> parkingMarkers = [];
  bool isLoading = true;
  LatLng? userLocation;
  List<Map<String, dynamic>> parkingGarages = [];
  final FirestoreService _firestoreService = FirestoreService();
  final String googleApiKey = "AIzaSyDaa-KNS7PvWNB1_MIbmmGcVmsFMbHBonA";
  String selectedSort = 'none';

  @override
  void initState() {
    super.initState();
    getUserLocationAndParking();
  }

  Future<void> getUserLocationAndParking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      userLocation = LatLng(position.latitude, position.longitude);

      await fetchNearbyParking(position.latitude, position.longitude);
    } catch (e) {
      print("\uD83D\uDEA8 Error getting location or parking data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading parking garages")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchNearbyParking(double lat, double lng) async {
    print("\uD83D\uDCCD Fetching nearby parking...");

    String url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=$lat,$lng"
        "&radius=2000"
        "&type=parking"
        "&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      setState(() {
        parkingMarkers = [];
        parkingGarages = [];
      });

      for (var place in results) {
        final loc = place['geometry']['location'];
        final name = place['name'];
        final placeId = place['place_id'];

        final marker = Marker(
          markerId: MarkerId(placeId),
          position: LatLng(loc['lat'], loc['lng']),
          infoWindow: InfoWindow(title: name),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () {
            setState(() {
              final tappedIndex =
                  parkingGarages.indexWhere((g) => g['place_id'] == placeId);
              if (tappedIndex != -1) {
                final tappedGarage = parkingGarages.removeAt(tappedIndex);
                parkingGarages.insert(0, tappedGarage);
              }
            });
          },
        );

        final garage = {
          'name': name,
          'lat': loc['lat'],
          'lng': loc['lng'],
          'place_id': placeId,
        };

        setState(() {
          parkingMarkers.add(marker);
          parkingGarages.add(garage);
        });

        final details =
            await fetchGarageInfoFromAPI(name, placeId, loc['lat'], loc['lng']);
        await _firestoreService.saveGarageDetails(placeId, details);
      }

      print("\u2705 Parking found: ${parkingGarages.length} garages");
      sortGarages();
    } else {
      throw Exception("Places API failed");
    }
  }

  Future<Map<String, dynamic>> fetchGarageInfoFromAPI(
      String name, String placeId, double lat, double lng) async {
    final googleDetailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId&fields=name,formatted_address,opening_hours,rating,user_ratings_total'
        '&key=$googleApiKey';

    final response = await http.get(Uri.parse(googleDetailsUrl));

    double baseRate = 2.5 + ((lat * lng) % 3);
    double hourMultiplier = (lat + lng) % 2 == 0 ? 1.0 : 1.5;
    double rate = double.parse((baseRate * hourMultiplier).toStringAsFixed(2));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];

      return {
        'name': result['name'],
        'address': result['formatted_address'],
        'open_hours':
            result['opening_hours']?['weekday_text']?.join(', ') ?? 'N/A',
        'rating': result['rating']?.toDouble() ?? 0.0,
        'total_ratings': result['user_ratings_total'] ?? '0',
        'hourly_rate': rate,
        'place_id': placeId,
      };
    } else {
      throw Exception('Failed to fetch garage details');
    }
  }

  void launchNavigation(
      double lat, double lng, String placeId, String name) async {
    final encodedName = Uri.encodeComponent(name);
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$placeId&travelmode=driving';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void sortGarages() async {
    List<Map<String, dynamic>> sorted = List.from(parkingGarages);

    final List<Map<String, dynamic>> enriched = [];
    for (final garage in sorted) {
      final data = await _firestoreService.getGarageDetails(garage['place_id']);
      if (data != null) {
        enriched.add({...garage, ...data});
      }
    }

    if (selectedSort.contains('price')) {
      enriched.sort((a, b) => selectedSort.contains('lowest')
          ? (a['hourly_rate'] as double).compareTo(b['hourly_rate'] as double)
          : (b['hourly_rate'] as double).compareTo(a['hourly_rate'] as double));
    } else if (selectedSort.contains('rating')) {
      enriched.sort((a, b) => selectedSort.contains('lowest')
          ? (a['rating'] as double).compareTo(b['rating'] as double)
          : (b['rating'] as double).compareTo(a['rating'] as double));
    }

    setState(() {
      parkingGarages = enriched;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3066BE),
        title: Text("Nearby Parking Garages",
            style: TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              selectedSort = value;
              sortGarages();
            },
            icon: Icon(Icons.filter_list, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'price_lowest', child: Text('Price: Low to High')),
              PopupMenuItem(
                  value: 'price_highest', child: Text('Price: High to Low')),
              PopupMenuItem(
                  value: 'rating_lowest', child: Text('Rating: Low to High')),
              PopupMenuItem(
                  value: 'rating_highest', child: Text('Rating: High to Low')),
            ],
          )
        ],
      ),
      body: isLoading || userLocation == null
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6190E8), Color(0xFFa7bfe8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: userLocation!,
                        zoom: 14,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: Set.from(parkingMarkers),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: ListView.builder(
                        itemCount: parkingGarages.length,
                        itemBuilder: (context, index) {
                          final garage = parkingGarages[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              title: Text(
                                garage['name'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.directions,
                                        color: Colors.blueAccent),
                                    tooltip: 'Navigate',
                                    onPressed: () {
                                      launchNavigation(
                                        garage['lat'],
                                        garage['lng'],
                                        garage['place_id'],
                                        garage['name'],
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline,
                                        color: Colors.teal),
                                    tooltip: 'Details',
                                    onPressed: () async {
                                      final data = await _firestoreService
                                          .getGarageDetails(garage['place_id']);
                                      if (data != null) {
                                        showModalBottomSheet(
                                          context: context,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          builder: (context) =>
                                              GarageDetailsBottomSheet(
                                                  data: data),
                                        );
                                      }
                                    },
                                  ),
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: _firestoreService
                                        .getGarageDetails(garage['place_id']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState !=
                                          ConnectionState.done) {
                                        return SizedBox.shrink();
                                      }

                                      final data = snapshot.data;
                                      final hasRate = data != null &&
                                          data['hourly_rate'] != null &&
                                          data['hourly_rate'] > 0;

                                      if (!hasRate) return SizedBox.shrink();

                                      return ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/reservation',
                                            arguments: data!,
                                          );
                                        },
                                        child: Text("Reserve"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF3066BE),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
