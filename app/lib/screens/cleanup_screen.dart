
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CleanupScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> report;

  const CleanupScreen({
    super.key,
    required this.reportId,
    required this.report,
  });

  @override
  State<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends State<CleanupScreen> {
  static const double allowedDistance = 100;
  static const double maxGpsAccuracy = 50;

  // Android emulator URL.
  // For a physical phone, replace this with your computer's
  // LAN IP address and port 8000, or your deployed backend URL.
  static const String backendUrl = 'https://tag-it-backend.onrender.com';

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController =
      TextEditingController();

  File? _afterImage;
  Position? _userPosition;
  double? _distance;
  bool _locationPassed = false;
  bool _checkingLocation = false;
  bool _submitting = false;

  String get _beforeImageUrl =>
      widget.report['imageUrl']?.toString() ?? '';

  double? _coordinate(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  double? get _reportLatitude =>
      _coordinate(widget.report['latitude']);

  double? get _reportLongitude =>
      _coordinate(widget.report['longitude']);

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

 
Future<void> _checkLocation() async {
  if (_checkingLocation) return;

  if (_reportLatitude == null || _reportLongitude == null) {
    _showMessage('This report has no valid GPS coordinates.');
    return;
  }

  setState(() {
    _checkingLocation = true;
    _locationPassed = false;
    _userPosition = null;
    _distance = null;
  });

  try {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled()
            .timeout(const Duration(seconds: 5));

    if (!mounted) return;

    if (!serviceEnabled) {
      _showMessage('Please enable device location and retry.');
      return;
    }

    var permission = await Geolocator.checkPermission()
        .timeout(const Duration(seconds: 5));

    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission()
          .timeout(const Duration(seconds: 15));
    }

    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      _showMessage('Location permission was denied.');
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Enable location permission in your device settings.',
      );
      return;
    }

    _showMessage('Getting your GPS location...');

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    ).timeout(const Duration(seconds: 20));

    if (!mounted) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _reportLatitude!,
      _reportLongitude!,
    );

    final passed = position.accuracy <= maxGpsAccuracy &&
        distance <= allowedDistance;

    setState(() {
      _userPosition = position;
      _distance = distance;
      _locationPassed = passed;
    });

    if (passed) {
      _showMessage(
        'Location check passed. You can submit your cleanup.',
      );
    } else if (position.accuracy > maxGpsAccuracy) {
      _showMessage('GPS accuracy is too low. Try again outdoors.');
    } else {
      _showMessage('You are outside the 100-metre cleanup radius.');
    }
  } on TimeoutException {
    if (mounted) {
      _showMessage(
        'Location timed out. Enable GPS and try again outdoors.',
      );
    }
  } catch (e, stackTrace) {
    debugPrint('CLEANUP LOCATION ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (mounted) {
      _showMessage('Unable to check location. Please retry.');
    }
  } finally {
    if (mounted) {
      setState(() => _checkingLocation = false);
    }
  }
}


  Future<void> _captureAfterPhoto() async {
    if (!_locationPassed) {
      _showMessage('Pass the location check first.');
      return;
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _afterImage = File(image.path);
        });
      }
    } catch (e) {
      _showMessage('Unable to open the camera.');
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$backendUrl/upload'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 90),
    );

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Image upload failed (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body)
        as Map<String, dynamic>;

    final imageUrl = data['image_url']?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('The upload did not return an image URL.');
    }

    return imageUrl;
  }

  Future<void> _submitCleanup() async {
    if (!_locationPassed || _userPosition == null) {
      _showMessage('Verify your location before submitting.');
      return;
    }

    if (_afterImage == null) {
      _showMessage('Capture an after-photo first.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Enter a description of the cleanup.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in to submit a cleanup.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final afterImageUrl = await _uploadImage(_afterImage!);

      final reportRef = FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId);

      final cleanupRef = FirebaseFirestore.instance
          .collection('cleanups')
          .doc();

      // Atomically save the cleanup and mark the original report cleaned.
      // This prevents two clients from successfully cleaning the same report.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final reportSnapshot = await transaction.get(reportRef);

        if (!reportSnapshot.exists) {
          throw Exception('The original report no longer exists.');
        }

        final reportData = reportSnapshot.data() as Map<String, dynamic>;
        final currentStatus =
            reportData['status']?.toString().trim().toLowerCase();

        if (currentStatus == 'cleaned') {
          throw Exception('This report has already been cleaned.');
        }

        final currentLat = _coordinate(reportData['latitude']);
        final currentLng = _coordinate(reportData['longitude']);

        if (currentLat == null || currentLng == null) {
          throw Exception('The report has no valid GPS coordinates.');
        }

        // Recheck distance against the latest report coordinates.
        final latestDistance = Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          currentLat,
          currentLng,
        );

        if (latestDistance > allowedDistance ||
            _userPosition!.accuracy > maxGpsAccuracy) {
          throw Exception(
            'Location verification is no longer valid. Check again.',
          );
        }

        transaction.set(cleanupRef, {
          'reportId': widget.reportId,
          'userId': user.uid,
          'userEmail': user.email,
          'beforeImageUrl': reportData['imageUrl'] ?? '',
          'afterImageUrl': afterImageUrl,
          'cleanupDescription': _descriptionController.text.trim(),
          'userLatitude': _userPosition!.latitude,
          'userLongitude': _userPosition!.longitude,
          'gpsAccuracy': _userPosition!.accuracy,
          'distanceFromReport': latestDistance,
          'locationCheckPassed': true,
          'status': 'submitted',
          'submittedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(reportRef, {
          'status': 'cleaned',
          'cleanedAt': FieldValue.serverTimestamp(),
          'cleanedBy': user.uid,
        });
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 48,
          ),
          title: const Text('Cleanup Submitted'),
          content: const Text(
            'Your before-and-after record has been saved.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showMessage('Could not submit cleanup: $e');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _locationStatus() {
    if (_checkingLocation) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Checking your location...')),
            ],
          ),
        ),
      );
    }

    if (_userPosition == null || _distance == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_searching),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location verification required',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You must be within 100 metres of the reported '
                'location, with sufficiently accurate GPS.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _checkLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Verify My Location'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final passed = _locationPassed;

    return Card(
      color: passed
          ? Colors.green.withOpacity(0.08)
          : Colors.orange.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  passed ? Icons.check_circle : Icons.warning_amber,
                  color: passed ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    passed
                        ? 'Location check passed'
                        : 'Location check failed',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Distance: ${_distance!.toStringAsFixed(1)} m',
            ),
            Text(
              'GPS accuracy: '
              '${_userPosition!.accuracy.toStringAsFixed(1)} m',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _checkingLocation
                  ? null
                  : _checkLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description =
        widget.report['description']?.toString() ??
        'No description provided';

    final canSubmit = _locationPassed &&
        _afterImage != null &&
        _descriptionController.text.trim().isNotEmpty &&
        !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean This Area'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Original Waste Report'),
            if (_beforeImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _beforeImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    alignment: Alignment.center,
                    color: Colors.grey.shade200,
                    child: const Text('Unable to load original image'),
                  ),
                ),
              )
            else
              const Text('No original image is available.'),
            const SizedBox(height: 10),
            Text(description),
            const SizedBox(height: 24),

            _sectionTitle('Step 1: Verify Your Location'),
            _locationStatus(),
            const SizedBox(height: 24),

            _sectionTitle('Step 2: Capture After-Photo'),
            OutlinedButton.icon(
              onPressed: _locationPassed
                  ? _captureAfterPhoto
                  : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Open Camera'),
            ),
            if (_afterImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _afterImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton.icon(
                onPressed: _locationPassed
                    ? _captureAfterPhoto
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Photo'),
              ),
            ],
            const SizedBox(height: 24),

            _sectionTitle('Step 3: Describe the Cleanup'),
            TextField(
              controller: _descriptionController,
              enabled: _locationPassed && !_submitting,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText:
                    'Describe the waste removed and the work completed...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: canSubmit ? _submitCleanup : null,
                icon: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _submitting
                      ? 'Submitting...'
                      : 'Submit Cleanup',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'After successful submission, this report will be marked '
              'as cleaned in the Community Feed.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
