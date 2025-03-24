import 'package:flutter/material.dart';

class GarageDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const GarageDetailsBottomSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data['name'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("📍 Address: ${data['address']}"),
          Text("💰 Rate: \$${data['hourly_rate']}/hr"),
          Text("🅿️ Available: ${data['available_spots']} spots"),
          Text("🕒 Hours: ${data['open_hours']}"),
          Text("⚡ EV Charging: ${data['has_ev_charging'] ? 'Yes' : 'No'}"),
        ],
      ),
    );
  }
}
