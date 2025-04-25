import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic> garageData;
  ReservationScreen({required this.garageData});

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  bool isLoading = false;
  bool isGsuUser = false;
  final TextEditingController gsuEmailController = TextEditingController();
  String? gsuError;
  bool discountApplied = false;

  double get hourlyRate => (widget.garageData['hourly_rate'] ?? 0.0).toDouble();
  double get discountPercent => 0.15;

  bool isValidGsuEmail(String email) {
    return email.endsWith('@gsu.edu') || email.endsWith('@student.gsu.edu');
  }

  void _showStyledSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void proceedToPayment() {
    setState(() {
      gsuError = null;
      discountApplied = false;
    });

    if (selectedDate == null ||
        selectedStartTime == null ||
        selectedEndTime == null) {
      _showStyledSnackBar("Please select date, start time, and end time.");
      return;
    }

    final start = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedStartTime!.hour,
      selectedStartTime!.minute,
    );

    final end = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedEndTime!.hour,
      selectedEndTime!.minute,
    );

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      _showStyledSnackBar("End time must be after start time.");
      return;
    }

    final gsuEmail = gsuEmailController.text.trim();
    if (isGsuUser && !isValidGsuEmail(gsuEmail)) {
      setState(() => gsuError = "Invalid GSU email address.");
      return;
    }

    final durationInMinutes = end.difference(start).inMinutes;
    final durationInHoursExact = durationInMinutes / 60;
    double amount = durationInHoursExact * hourlyRate;

    if (isGsuUser && isValidGsuEmail(gsuEmail)) {
      amount = amount * (1 - discountPercent);
      discountApplied = true;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          garageData: widget.garageData,
          duration: durationInHoursExact,
          durationInMinutes: durationInMinutes,
          startTime: start,
          garageName: widget.garageData['name'] ?? 'Unknown Garage',
          garageId: widget.garageData['place_id'] ?? 'unknown_id',
          finalAmount: double.parse(amount.toStringAsFixed(2)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gsuEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.garageData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3066BE),
        title: Text("Reservation", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6190E8), Color(0xFFa7bfe8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text("Garage: ${data['name']}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text("Address: ${data['address']}",
                    style: TextStyle(color: Colors.white)),
                Text("Rate: \$${hourlyRate.toStringAsFixed(2)}/hr",
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 20),
                _buildTile(
                  label: "Date",
                  value: selectedDate != null
                      ? DateFormat('yMMMd').format(selectedDate!)
                      : "Select date",
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: now.add(Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                _buildTile(
                  label: "Start Time",
                  value: selectedStartTime != null
                      ? selectedStartTime!.format(context)
                      : "Select start time",
                  icon: Icons.access_time,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedStartTime = picked);
                    }
                  },
                ),
                _buildTile(
                  label: "End Time",
                  value: selectedEndTime != null
                      ? selectedEndTime!.format(context)
                      : "Select end time",
                  icon: Icons.access_time,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedEndTime = picked);
                    }
                  },
                ),
                SizedBox(height: 16),
                CheckboxListTile(
                  value: isGsuUser,
                  title: Text("I am a GSU student or employee",
                      style: TextStyle(color: Colors.white)),
                  activeColor: Color(0xFF3066BE),
                  checkColor: Colors.white,
                  onChanged: (val) => setState(() => isGsuUser = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (isGsuUser) ...[
                  TextField(
                    controller: gsuEmailController,
                    onChanged: (val) {
                      setState(() {
                        gsuError = null;
                        discountApplied = false;
                        if (isValidGsuEmail(val.trim())) {
                          discountApplied = true;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: "GSU Email",
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: Color(0xFF3066BE), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: Color(0xFF3066BE), width: 2),
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                  if (gsuError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4),
                      child: Text(
                        gsuError!,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  if (discountApplied)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4),
                      child: Text(
                        "15% GSU discount applied!",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                ],
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3066BE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Proceed to Payment",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        trailing: Icon(icon),
        onTap: onTap,
      ),
    );
  }
}
