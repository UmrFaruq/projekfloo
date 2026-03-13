import 'package:flutter/material.dart';
import '../data/order_data.dart';
import '../models/order.dart';
import '../theme/colors.dart';
import 'report_result_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {

  DateTime? startDate;
  DateTime? endDate;

  Future pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  List<Order> getFilteredOrders() {

    if (startDate == null || endDate == null) return [];

    return allOrders.value.where((order) {

      return order.date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
             order.date.isBefore(endDate!.add(const Duration(days: 1)));

    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: PastelColors.mint,

      appBar: AppBar(
        backgroundColor: PastelColors.mint,
        elevation: 0,
        title: const Text(
          "Reports",
          style: TextStyle(color: PastelColors.grey),
        ),
        iconTheme: const IconThemeData(color: PastelColors.grey),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Select Report Date",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// START DATE
            GestureDetector(
              onTap: pickStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      startDate == null
                          ? "Start Date"
                          : "${startDate!.day}/${startDate!.month}/${startDate!.year}",
                    ),

                    const Icon(Icons.calendar_today)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// END DATE
            GestureDetector(
              onTap: pickEndDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      endDate == null
                          ? "End Date"
                          : "${endDate!.day}/${endDate!.month}/${endDate!.year}",
                    ),

                    const Icon(Icons.calendar_today)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.teal,
                ),
                onPressed: () {

                  if (startDate == null || endDate == null) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Select date first"),
                        backgroundColor: Colors.red,
                      ),
                    );

                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportResultScreen(
                        orders: getFilteredOrders(),
                      ),
                    ),
                  );

                },
                child: const Text("Generate Report"),
              ),
            )
          ],
        ),
      ),
    );
  }
}