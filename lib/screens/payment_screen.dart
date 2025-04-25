import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> garageData;
  final double duration;
  final int durationInMinutes;
  final DateTime startTime;
  final String garageName;
  final String garageId;
  final double finalAmount;

  const PaymentScreen({
    required this.garageData,
    required this.duration,
    required this.durationInMinutes,
    required this.startTime,
    required this.garageName,
    required this.garageId,
    required this.finalAmount,
    Key? key,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CardFieldInputDetails? _card;
  bool _loading = false;

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
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration(milliseconds: 250));
    setState(() {});
    await Future.delayed(Duration(milliseconds: 100));

    if (!_formKey.currentState!.validate()) return;

    if (_card == null || !_card!.complete) {
      _showError("Please complete all card fields.");
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final callable =
          FirebaseFunctions.instance.httpsCallable('createStripePayment');
      final response = await callable.call({
        'amount': (widget.finalAmount * 100).toInt(),
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

      final last4 = paymentMethod.card?.last4 ?? "****";
      final endTime =
          widget.startTime.add(Duration(minutes: widget.durationInMinutes));

      await FirebaseFirestore.instance.collection('reservations').add({
        'uid': user.uid,
        'garageId': widget.garageId,
        'garageName': widget.garageName,
        'startTime': widget.startTime,
        'endTime': endTime,
        'duration': double.parse(widget.duration.toStringAsFixed(2)),
        'durationInMinutes': widget.durationInMinutes,
        'amount': double.parse(widget.finalAmount.toStringAsFixed(2)),
        'hourly_rate': widget.garageData['hourly_rate'] ?? 0.0,
        'nameOnCard': _nameController.text,
        'cardLast4': last4,
        'status': 'active',
        'createdAt': Timestamp.now(),
      });

      _showSuccess("Payment successful & reservation saved.");
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      print("Payment error: $e");
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('card details not complete')) {
        _showError("Please complete all card details before proceeding.");
      } else if (errorMessage.contains('stripeexception')) {
        _showError("Payment failed. Please check your card information.");
      } else {
        _showError("Something went wrong. Please try again.");
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3066BE),
        title: Text("Payment", style: TextStyle(color: Colors.white)),
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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    "Total: \$${widget.finalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: "Name on Card",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? "Enter name on card"
                        : null,
                  ),
                  SizedBox(height: 16),
                  CardField(
                    onCardChanged: (details) {
                      setState(() => _card = details);
                      print("🧾 Card complete: ${details?.complete}");
                    },
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
                                CircularProgressIndicator(color: Colors.white),
                          )
                        : ElevatedButton(
                            onPressed: _handlePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3066BE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text("Pay and Reserve",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
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
