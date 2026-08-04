import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class ReportScreen extends StatefulWidget {

  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();

}

class _ReportScreenState extends State<ReportScreen> {
 
  final ImagePicker picker = ImagePicker();
  XFile? image;
Future<void> captureImage() async {
  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
  );

  if (photo != null) {
    setState(() {
      image = photo;
    });

    print(photo.path);
  }
}

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
       Container(
         height: 250,
          width: double.infinity,
        decoration: BoxDecoration(
         border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
         ),
            child: image == null
        ? const Center(
          child: Text("No image selected"),
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(image!.path),
            fit: BoxFit.cover,
          ),
        ),
),

        const SizedBox(height: 20),

ElevatedButton(
  onPressed: captureImage,
  child: const Text("Capture Image"),
),
            SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describe the waste...",
              ),
            ),

            SizedBox(height: 20),

       Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         const Text(
         "Location",
         style: TextStyle(
        fontWeight: FontWeight.bold,
        ),
      ),

       const SizedBox(height: 8),

        const Text(
      "📍 Waiting for image capture...",
       ),
      ],
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