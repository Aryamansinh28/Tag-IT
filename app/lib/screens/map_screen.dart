
import 'dart:typed_data';
import 'dart:math' as math;
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
  Map<String, Map<String, dynamic>> reportData = {};
  Map<String, BitmapDescriptor> circleIcons = {};
  Set<Circle> heatmapCircles = {};
  bool showHeatmap = false;

  String severityFilter = 'All';
  String? selectedReportId;

  static const LatLng fallbackLocation = LatLng(11.0168, 76.9558);

  @override
  void initState() {
    super.initState();
    _createCircleIcons();
  }

  Future<BitmapDescriptor> _drawCircle(Color color) async {
    const double size = 100;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Subtle outer ring
    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.22);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      46,
      outerPaint,
    );

    // White outline
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      27,
      outlinePaint,
    );

    // Solid severity-colored circle
    final circlePaint = Paint()..color = color;

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      24,
      circlePaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    picture.dispose();

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.bytes(
      Uint8List.view(
        byteData.buffer,
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
  }

  Future<void> _createCircleIcons() async {
    final icons = <String, BitmapDescriptor>{
      'high': await _drawCircle(Colors.red),
      'medium': await _drawCircle(Colors.orange),
      'low': await _drawCircle(Colors.green),
      'unknown': await _drawCircle(Colors.blueGrey),
    };

    if (!mounted) return;

    setState(() {
      circleIcons = icons;
    });
  }

  Color severityColor(String? severity) {
    switch (severity?.toLowerCase().trim()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String displaySeverity(dynamic severity) {
    if (severity == null || severity.toString().trim().isEmpty) {
      return 'Unknown';
    }

    return severity.toString();
  }

  BitmapDescriptor _iconForSeverity(String severity) {
    return circleIcons[severity.toLowerCase()] ??
        circleIcons['unknown'] ??
        BitmapDescriptor.defaultMarker;
  }

  void _moveCameraToReports() {
    if (mapController == null || markers.isEmpty) return;

    if (markers.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: markers.first.position,
            zoom: 15,
          ),
        ),
      );
      return;
    }

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final marker in markers) {
      final position = marker.position;

      if (position.latitude < minLat) minLat = position.latitude;
      if (position.latitude > maxLat) maxLat = position.latitude;
      if (position.longitude < minLng) minLng = position.longitude;
      if (position.longitude > maxLng) maxLng = position.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  Set<Circle> buildHeatmap(List<LatLng> locations) {
    final circles = <Circle>{};

    for (int i = 0; i < locations.length; i++) {
      final point = locations[i];
      int nearbyReports = 0;

      for (final other in locations) {
        final latDifference =
            (point.latitude - other.latitude) * 111000;
        final lngDifference =
            (point.longitude - other.longitude) *
                111000 *
                math.cos(point.latitude * math.pi / 180);

        final distance = math.sqrt(
          latDifference * latDifference +
              lngDifference * lngDifference,
        );

        if (distance <= 300) {
          nearbyReports++;
        }
      }

      final Color color;
      if (nearbyReports >= 5) {
        color = Colors.red;
      } else if (nearbyReports >= 3) {
        color = Colors.orange;
      } else {
        color = Colors.yellow;
      }

      circles.add(
        Circle(
          circleId: CircleId('hotspot_$i'),
          center: point,
          radius: 250,
          fillColor: color.withValues(alpha: 0.20),
          strokeColor: color.withValues(alpha: 0.35),
          strokeWidth: 1,
        ),
      );
    }

    return circles;
  }

  String _formatTimestamp(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Date not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String? _getPhotoUrl(Map<String, dynamic> data) {
    // Try common field names for uploaded report images.
    for (final key in [
      'imageUrl',
      'imageURL',
      'photoUrl',
      'image',
      'photo',
      'imageKitUrl',
    ]) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Waste Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: showHeatmap ? 'Show report circles' : 'Show heatmap',
            icon: Icon(
              showHeatmap
                  ? Icons.location_on
                  : Icons.local_fire_department,
            ),
            onPressed: () {
              setState(() {
                showHeatmap = !showHeatmap;
                selectedReportId = null;
              });
            },
          ),
          IconButton(
            tooltip: 'Show all visible reports',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _moveCameraToReports,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading reports:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];
          final newMarkers = <Marker>{};
          final newReportData = <String, Map<String, dynamic>>{};

          // Build hotspot circles from all reports with valid coordinates.
          final allLocations = <LatLng>[];
          for (final document in documents) {
            final data = document.data();
            final latitude = data['latitude'];
            final longitude = data['longitude'];

            if (latitude is num && longitude is num) {
              allLocations.add(
                LatLng(latitude.toDouble(), longitude.toDouble()),
              );
            }
          }
          heatmapCircles = buildHeatmap(allLocations);

          for (final document in documents) {
            final data = document.data();
            final latitude = data['latitude'];
            final longitude = data['longitude'];

            if (latitude is! num || longitude is! num) continue;

            final severity = displaySeverity(data['severity']);

            if (severityFilter != 'All' &&
                severity.toLowerCase() != severityFilter.toLowerCase()) {
              continue;
            }

            final position = LatLng(
              latitude.toDouble(),
              longitude.toDouble(),
            );

            newReportData[document.id] = data;

            newMarkers.add(
              Marker(
                markerId: MarkerId(document.id),
                position: position,
                icon: _iconForSeverity(severity),
                anchor: const Offset(0.5, 0.5),
                onTap: () {
                  setState(() {
                    selectedReportId = document.id;
                  });
                },
                infoWindow: InfoWindow(
                  title: data['wasteType']?.toString() ??
                      data['aiWasteType']?.toString() ??
                      'Waste Report',
                  snippet: 'Severity: $severity',
                ),
              ),
            );
          }

          markers = newMarkers;
          reportData = newReportData;

          if (selectedReportId != null &&
              !reportData.containsKey(selectedReportId)) {
            selectedReportId = null;
          }

          final selectedData = selectedReportId == null
              ? null
              : reportData[selectedReportId];

          final selectedSeverity = selectedData == null
              ? 'Unknown'
              : displaySeverity(selectedData['severity']);

          final photoUrl = selectedData == null
              ? null
              : _getPhotoUrl(selectedData);

          return Column(
            children: [
              // Severity filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: ['All', 'High', 'Medium', 'Low', 'Unknown']
                      .map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: severityFilter == filter,
                        onSelected: (_) {
                          setState(() {
                            severityFilter = filter;
                            selectedReportId = null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Map and report details
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: markers.isNotEmpty
                            ? markers.first.position
                            : fallbackLocation,
                        zoom: markers.isNotEmpty ? 13 : 10,
                      ),
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                      markers: showHeatmap ? <Marker>{} : markers,
                      circles: showHeatmap ? heatmapCircles : <Circle>{},
                      zoomControlsEnabled: true,
                      myLocationButtonEnabled: false,
                      onTap: (_) {
                        setState(() {
                          selectedReportId = null;
                        });
                      },
                    ),

                    if (selectedData != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Card(
                          elevation: 8,
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedData['wasteType']
                                                  ?.toString() ??
                                              selectedData['aiWasteType']
                                                  ?.toString() ??
                                              'Waste Report',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedReportId = null;
                                          });
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),

                                  // Report photo
                                  if (photoUrl != null) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        photoUrl,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          progress,
                                        ) {
                                          if (progress == null) return child;

                                          return const SizedBox(
                                            height: 180,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 100,
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Could not load report photo',
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      const Text('Severity: '),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: severityColor(
                                            selectedSeverity,
                                          ).withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          selectedSeverity,
                                          style: TextStyle(
                                            color: severityColor(
                                              selectedSeverity,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    selectedData['aiDescription']?.toString() ??
                                        selectedData['description']?.toString() ??
                                        'No description available.',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  if (selectedData['location'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Location: ${selectedData['location']}',
                                    ),
                                  ],

                                  const SizedBox(height: 6),

                                  Text(
                                    'Reported: ${_formatTimestamp(selectedData['createdAt'])}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  showHeatmap
                      ? '${heatmapCircles.length} hotspot area(s) shown'
                      : '${markers.length} waste report(s) on map',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
