import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;

  Set<Marker> markers = {};

  bool hasMovedToReports = false;

  static const LatLng fallbackLocation =
      LatLng(11.0168, 76.9558);

  BitmapDescriptor? reportMarkerIcon;

  @override
  void initState() {
    super.initState();
    createReportMarker();
  }

  Future<void> createReportMarker() async {
    const double size = 80;

    final recorder = ui.PictureRecorder();

    final canvas = Canvas(recorder);

    // Outer subtle circle
    final outerPaint = Paint()
      ..color = const Color(0x332E7D32);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      30,
      outerPaint,
    );

    // Inner circle
    final innerPaint = Paint()
      ..color = const Color(0xFF2E7D32);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      12,
      innerPaint,
    );

    final picture = recorder.endRecording();

    final image = await picture.toImage(
      size.toInt(),
      size.toInt(),
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      return;
    }

    final Uint8List bytes =
        byteData.buffer.asUint8List();

    setState(() {
      reportMarkerIcon =
          BitmapDescriptor.bytes(bytes);
    });
  }

  void onMapCreated(
    GoogleMapController controller,
  ) {
    mapController = controller;

    if (markers.isNotEmpty &&
        !hasMovedToReports) {
      moveCameraToMarkers();
    }
  }

  Future<void> moveCameraToMarkers() async {
    if (mapController == null ||
        markers.isEmpty ||
        hasMovedToReports) {
      return;
    }

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final marker in markers) {
      final latitude =
          marker.position.latitude;

      final longitude =
          marker.position.longitude;

      if (latitude < minLat) {
        minLat = latitude;
      }

      if (latitude > maxLat) {
        maxLat = latitude;
      }

      if (longitude < minLng) {
        minLng = longitude;
      }

      if (longitude > maxLng) {
        maxLng = longitude;
      }
    }

    if (minLat == double.infinity) {
      return;
    }

    hasMovedToReports = true;

    if (minLat == maxLat &&
        minLng == maxLng) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              minLat,
              minLng,
            ),
            zoom: 15,
          ),
        ),
      );

      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        minLat,
        minLng,
      ),
      northeast: LatLng(
        maxLat,
        maxLng,
      ),
    );

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Waste Map",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  "Error loading reports:\n\n"
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final reports =
              snapshot.data?.docs ?? [];

          final Set<Marker> newMarkers = {};

          for (final document in reports) {
            final data =
                document.data()
                    as Map<String, dynamic>;

            final latitude =
                data["latitude"];

            final longitude =
                data["longitude"];

            if (latitude == null ||
                longitude == null) {
              continue;
            }

            newMarkers.add(
              Marker(
                markerId:
                    MarkerId(document.id),

                position: LatLng(
                  latitude.toDouble(),
                  longitude.toDouble(),
                ),

                icon: reportMarkerIcon ??
                    BitmapDescriptor.defaultMarker,

                infoWindow: InfoWindow(
                  title: "Waste Report",
                  snippet:
                      data["description"] ??
                          "No description",
                ),
              ),
            );
          }

          markers = newMarkers;

          if (markers.isNotEmpty &&
              !hasMovedToReports) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              moveCameraToMarkers();
            });
          }

          return GoogleMap(
            initialCameraPosition:
                CameraPosition(
              target: markers.isNotEmpty
                  ? markers.first.position
                  : fallbackLocation,
              zoom: markers.isNotEmpty
                  ? 15
                  : 10,
            ),

            onMapCreated: onMapCreated,

            markers: markers,

            zoomControlsEnabled: true,

            myLocationButtonEnabled: false,
          );
        },
      ),
    );
  }
}