import 'package:flutter/material.dart';

class GarageDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const GarageDetailsBottomSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Text(
            data['name'] ?? 'No name',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _infoRow("📍 Address", data['address'] ?? 'N/A'),
          _infoRow(
              "⭐ Rating",
              "${data['rating'] ?? 'N/A'} "
                  "(${data['total_ratings'] ?? '0'} reviews)"),
          _infoRow("💵 Rate",
              "\$${(data['hourly_rate'] ?? 0).toStringAsFixed(2)}/hr"),
          _infoRow("🕒 Hours", data['open_hours'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}
