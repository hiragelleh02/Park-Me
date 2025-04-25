import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/parking_space_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> addParkingSpace(ParkingSpace space) async {
    await _db.collection('parking_spaces').doc(space.id).set(space.toMap());
  }

  Future<List<ParkingSpace>> getAvailableSpaces() async {
    QuerySnapshot snapshot = await _db
        .collection('parking_spaces')
        .where('isAvailable', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => ParkingSpace.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Save parking garage info
  Future<void> saveGarageDetails(
      String placeId, Map<String, dynamic> data) async {
    await _db.collection('garages').doc(placeId).set(data);
  }

  // Get garage details by placeId
  Future<Map<String, dynamic>?> getGarageDetails(String placeId) async {
    final doc = await _db.collection('garages').doc(placeId).get();
    return doc.exists ? doc.data() : null;
  }
}
