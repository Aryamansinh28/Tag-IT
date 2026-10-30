import 'dart:io';
import '../services/image_upload_service.dart';
import '../services/waste_analysis_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ImagePicker picker = ImagePicker();

  final TextEditingController descriptionController =
      TextEditingController();

  XFile? image;
  Position? position;

  String locationMessage = "Capture an image to detect location.";
  bool isSubmitting = false;

  Future<void> captureImage() async {
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (photo != null) {
      setState(() {
        image = photo;
        locationMessage = "Getting location...";
      });

      print("Image captured. Getting location...");

      await getLocation();

      print(photo.path);
    }
  }


Future<void> getLocation() async {
  try {
    if (mounted) {
      setState(() {
        locationMessage = "Checking location services...";
      });
    }

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          locationMessage = "Enable location services on your device.";
        });
      }
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          locationMessage = "Location permission is required.";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        locationMessage = "Getting coordinates...";
      });
    }

    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    if (!mounted) return;

    setState(() {
      position = currentPosition;
      locationMessage =
          "${currentPosition.latitude.toStringAsFixed(6)}, "
          "${currentPosition.longitude.toStringAsFixed(6)}";
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      locationMessage =
          "Couldn't get location. Check GPS and try again.";
    });

    debugPrint("LOCATION ERROR: $e");
  }
}


  Future<void> submitReport() async {
    // Prevent repeated taps from uploading/analyzing/submitting the
    // same report more than once while this operation is in progress.
    if (isSubmitting) return;

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture an image first.")),
      );
      return;
    }

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location is required.")),
      );
      return;
    }

    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe the waste.")),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login before submitting.")),
      );
      return;
    }

    // Capture values once, so the form cannot change the data mid-submit.
    final File photoFile = File(image!.path);
    final double latitude = position!.latitude;
    final double longitude = position!.longitude;

    setState(() {
      isSubmitting = true;
    });

    try {
      debugPrint("REPORT: uploading image...");
      final imageUrl = await ImageUploadService.uploadImage(photoFile);
      debugPrint("REPORT: image uploaded successfully");

      debugPrint("REPORT: analyzing image with Gemini...");
      final aiAnalysis = await WasteAnalysisService.analyzeImage(imageUrl);
      debugPrint("REPORT: AI analysis completed");

      // Create exactly one document only after upload and analysis succeed.
      // Store all report fields together to avoid separate feed entries.
      final reportRef =
          FirebaseFirestore.instance.collection("reports").doc();

      await reportRef.set({
        "userId": user.uid,
        "description": description,
        "latitude": latitude,
        "longitude": longitude,
        "timestamp": FieldValue.serverTimestamp(),
        "imageUrl": imageUrl,
        "wasteDetected": aiAnalysis["waste_detected"],
        "wasteType": aiAnalysis["waste_type"],
        "aiDescription": aiAnalysis["description"],
        "severity": aiAnalysis["severity"],
        "analysisStatus": "completed",
      });

      debugPrint("REPORT: report submitted successfully");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted successfully!"),
        ),
      );
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint("REPORT ERROR: $e");
      debugPrint("$stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to submit report. Please try again.",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Report Waste",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Help identify waste in your community.",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Capture the waste, describe the problem and "
              "we'll automatically record its location.",
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Step 1
            const Text(
              "1. Capture waste",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 230,
                width: double.infinity,
                child: image == null
                    ? InkWell(
                        onTap: captureImage,
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [

                            Container(
                              padding:
                                  const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 36,
                                color: primaryColor,
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Text(
                              "Capture a photo",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Camera capture only",
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [

                          Image.file(
                            File(image!.path),
                            fit: BoxFit.cover,
                          ),

                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: ElevatedButton.icon(
                              onPressed: captureImage,
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 18,
                              ),
                              label: const Text(
                                "Retake",
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // Step 2
            const Text(
              "2. Describe the waste",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    "Example: Large pile of plastic waste "
                    "near the roadside...",
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 58,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Step 3
            const Text(
              "3. Location",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [

                    Container(
                      padding:
                          const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            position == null
                                ? "Location"
                                : "Location detected",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            locationMessage,
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (position != null)
                      Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : submitReport,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    isSubmitting ? "Submitting..." : "Submit Report",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                "Your report helps the community identify "
                "waste hotspots.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}