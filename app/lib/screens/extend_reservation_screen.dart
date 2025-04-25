import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ExtendReservationScreen extends StatefulWidget {
  final DocumentSnapshot reservationDoc;

  const ExtendReservationScreen({required this.reservationDoc, Key? key})
      : super(key: key);

  @override
  State<ExtendReservationScreen> createState() =>
      _ExtendReservationScreenState();
}

class _ExtendReservationScreenState extends State<ExtendReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minutesController = TextEditingController();
  CardFieldInputDetails? _card;
  bool _loading = false;

  double _calculateExtraAmount(int extraMinutes) {
    final double rate = (widget.reservationDoc['hourly_rate'] ??
            widget.reservationDoc['rate'] ??
            0.0)
        .toDouble();
    return double.parse(((extraMinutes / 60.0) * rate).toStringAsFixed(2));
  }

  Future<void> _handleExtensionPayment() async {
    try {
      final minutes = int.tryParse(_minutesController.text);
      if (!_formKey.currentState!.validate() ||
          _card == null ||
          !_card!.complete ||
          minutes == null ||
          minutes <= 0) {
        _showError("Please enter valid minutes and card info.");
        return;
      }

      final double extraAmount = _calculateExtraAmount(minutes);
      if (extraAmount < 0.5) {
        _showError("Minimum charge must be \$0.50.");
        return;
      }

      setState(() => _loading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final callable =
          FirebaseFunctions.instance.httpsCallable('createStripePayment');
      final response = await callable.call({
        'amount': (extraAmount * 100).toInt(),
        'currency': 'usd',
      });
      final clientSecret = response.data['clientSecret'];

      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: _nameController.text),
          ),
        ),
      );

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethod.id,
          ),
        ),
      );

      final docRef = widget.reservationDoc.reference;
      final data = widget.reservationDoc.data() as Map<String, dynamic>;

      final int oldMinutes = data['durationInMinutes'] ?? 0;
      final double oldDuration = (data['duration'] ?? 0.0).toDouble();
      final double oldAmount = (data['amount'] ?? 0.0).toDouble();
      final DateTime startTime = data['startTime'].toDate();

      final int newMinutes = oldMinutes + minutes;
      final double newDuration = oldDuration + (minutes / 60.0);
      final double newAmount = oldAmount + extraAmount;
      final DateTime newEndTime = startTime.add(Duration(minutes: newMinutes));

      await docRef.update({
        'duration': double.parse(newDuration.toStringAsFixed(2)),
        'durationInMinutes': newMinutes,
        'amount': double.parse(newAmount.toStringAsFixed(2)),
        'endTime': Timestamp.fromDate(newEndTime),
        'extendedAt': Timestamp.now(),
        'lastExtensionAmount': extraAmount,
        'extensionCardLast4': paymentMethod.card?.last4 ?? "****",
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                  child: Text("Reservation extended!",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showError("Payment failed. Please try again.");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
                child: Text(message, style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final garageName = widget.reservationDoc['garageName'] ?? 'Garage';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3066BE),
        title:
            Text("Extend: $garageName", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6190E8), Color(0xFFa7bfe8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text("Enter extra time (in minutes):",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "e.g. 30",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter minutes" : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Name on Card",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter name" : null,
                  ),
                  SizedBox(height: 16),
                  CardField(
                    onCardChanged: (details) => _card = details,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _loading
                        ? Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _handleExtensionPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3066BE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              "Pay and Extend",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
