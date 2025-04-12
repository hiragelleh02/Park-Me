import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> faqs = const [
    {
      "question": "How do I reserve a parking spot?",
      "answer":
          "Go to any garage listed in the app, select your duration, and proceed to payment using a valid card."
    },
    {
      "question": "Can I cancel a reservation?",
      "answer":
          "Yes, go to 'My Reservations', find the reservation, and tap the cancel button."
    },
    {
      "question": "Will I be charged if I cancel late?",
      "answer":
          "Yes, if you cancel less than 60 minutes before the start time, a 20% cancellation fee will apply."
    },
    {
      "question": "How do I extend my reservation?",
      "answer":
          "Tap the clock icon next to your active reservation to add extra time and pay the additional amount."
    },
    {
      "question": "What happens after my reservation ends?",
      "answer":
          "Your reservation moves to the Past section. Reservations are kept for 30 days for your reference. You can also click the delete button to remove it completely."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3066BE),
        title: Text("FAQs", style: TextStyle(color: Colors.white)),
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
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 12),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    faq["question"]!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        faq["answer"]!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
