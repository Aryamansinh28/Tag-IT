import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Report Waste"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text("Upload Image"),
            ),

            SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describe the waste...",
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {},
              child: const Text("Get Location"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {},
              child: const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }
}