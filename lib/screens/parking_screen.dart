// lib/screens/parking_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/firestore_service.dart';
import '../services/fake_parking_details_api.dart';
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
      print("\u{1F6A8} Error getting location or parking data: $e");
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

        final exists = await _firestoreService.getGarageDetails(placeId);
        if (exists == null) {
          final details = await fetchGarageInfoFromAPI(name, placeId);
          await _firestoreService.saveGarageDetails(placeId, details);
        }
      }
    } else {
      throw Exception("Places API failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearby Parking Garages")),
      body: isLoading || userLocation == null
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                  child: ListView.builder(
                    itemCount: parkingGarages.length,
                    itemBuilder: (context, index) {
                      final garage = parkingGarages[index];
                      return ListTile(
                        title: Text(garage['name']),
                        subtitle: Text("Tap to view details"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.info),
                              onPressed: () async {
                                final data = await _firestoreService
                                    .getGarageDetails(garage['place_id']);
                                if (data != null) {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) =>
                                        GarageDetailsBottomSheet(data: data),
                                  );
                                }
                              },
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final data = await _firestoreService
                                    .getGarageDetails(garage['place_id']);
                                if (data != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReservationScreen(garageData: data),
                                    ),
                                  );
                                }
                              },
                              child: Text("Reserve"),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
