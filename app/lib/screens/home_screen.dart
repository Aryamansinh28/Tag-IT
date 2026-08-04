import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle : true,
          title : Text("Tag IT",
          style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
           ),
        )
        ),
        body: Center(
       
       child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
     
      children: [
      const Text(
        "TrashTagger 🌍",
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 15),

      const Text(
        "Report waste. Keep cities clean.",
      ),

      const SizedBox(height: 40),

      ElevatedButton(
        onPressed: () {},
        child: const Text("Report Trash"),
      ),

      const SizedBox(height: 15),

      ElevatedButton(
        onPressed: () {},
        child: const Text("View Map"),
      ),

      const SizedBox(height: 15),

      ElevatedButton(
        onPressed: () {},
        child: const Text("Community Feed"),
      ),
    ],
  ),

        ),
          
        
      );
  }
}