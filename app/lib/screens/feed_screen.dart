
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cleanup_screen.dart';
import 'cleaned_projects_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String selectedSeverity = 'All';

  final List<String> severityFilters = [
    'All',
    'High',
    'Medium',
    'Low',
    'Unknown',
  ];

  Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange.shade800;
      case 'low':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _displayWasteType(Map<String, dynamic> report) {
    // Try the supported classification fields in priority order.
    const fields = [
      'wasteType',
      'aiWasteType',
      'waste_type',
      'predictedWasteType',
    ];

    for (final field in fields) {
      final value = report[field];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isEmpty ||
          text.toLowerCase() == 'none' ||
          text.toLowerCase() == 'null' ||
          text.toLowerCase() == 'n/a') {
        continue;
      }

      return text;
    }

    return 'Unidentified';
  }

  String normalizeSeverity(dynamic value) {
    final severity = value?.toString().toLowerCase().trim();

    if (severity == 'high' ||
        severity == 'medium' ||
        severity == 'low') {
      return severity!;
    }

    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CleanedProjectsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Cleaned Projects'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyFeed();
          }

          final allReports = snapshot.data!.docs;

          final filteredReports = allReports.where((document) {
            final report =
                document.data() as Map<String, dynamic>;

            final severity = normalizeSeverity(report['severity']);

            return selectedSeverity == 'All' ||
                severity == selectedSeverity.toLowerCase();
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by severity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: severityFilters.map((filter) {
                          final selected = selectedSeverity == filter;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  selectedSeverity = filter;
                                });
                              },
                              selectedColor:
                                  primaryColor.withOpacity(0.15),
                              checkmarkColor: primaryColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Text(
                      '${filteredReports.length} report'
                      '${filteredReports.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredReports.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No reports found for this severity.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16, 8, 16, 32,
                        ),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report =
                              filteredReports[index].data()
                                  as Map<String, dynamic>;

                          final description =
                              report['description']?.toString() ??
                                  'No description provided';

                          final imageUrl =
                              report['imageUrl']?.toString();

                          final wasteType = _displayWasteType(report);

                          final aiDescription =
                              report['aiDescription']?.toString() ??
                                  '';

                          final severity =
                              normalizeSeverity(report['severity']);

                          final wasteDetected =
                              report['wasteDetected'];

                          final latitude = report['latitude'];
                          final longitude = report['longitude'];
                          final timestamp = report['timestamp'];
                          final isCleaned = report['status']
                                  ?.toString()
                                  .trim()
                                  .toLowerCase() ==
                              'cleaned';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: primaryColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Waste Report',
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Community report',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.more_horiz,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  if (imageUrl != null &&
                                      imageUrl.isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          progress,
                                        ) {
                                          if (progress == null) {
                                            return child;
                                          }

                                          return const SizedBox(
                                            height: 220,
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
                                            height: 120,
                                            alignment: Alignment.center,
                                            color: Colors.grey.shade100,
                                            child: const Text(
                                              'Unable to load report image',
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // AI analysis section
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.auto_awesome,
                                              color: primaryColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'AI Waste Analysis',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _InfoBadge(
                                              icon: Icons.category_outlined,
                                              label: 'Waste type: $wasteType',
                                            ),
                                            if (wasteDetected == false)
                                              const _InfoBadge(
                                                icon: Icons.info_outline,
                                                label: 'No waste detected',
                                              ),
                                            _InfoBadge(
                                              icon: Icons.warning_amber,
                                              label:
                                                  '${severity[0].toUpperCase()}${severity.substring(1)} severity',
                                              color:
                                                  severityColor(severity),
                                            ),
                                          ],
                                        ),

                                        if (aiDescription.trim().isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            aiDescription,
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontSize: 13,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Reported location
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 20,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Reported location',
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                latitude != null &&
                                                        longitude != null
                                                    ? '${latitude.toString()}, '
                                                        '${longitude.toString()}'
                                                    : 'Location unavailable',
                                                style: TextStyle(
                                                  color:
                                                      Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  if (isCleaned)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.35),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Cleaned',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        icon: const Icon(
                                          Icons.cleaning_services_outlined,
                                        ),
                                        label: const Text('Clean This Area'),
                                        onPressed: () async {
                                          final result =
                                              await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CleanupScreen(
                                                reportId:
                                                    filteredReports[index].id,
                                                report: report,
                                              ),
                                            ),
                                          );

                                          if (result == true && mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Cleanup submitted successfully.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),

                                  const SizedBox(height: 14),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        timestamp is Timestamp
                                            ? _formatTimestamp(timestamp)
                                            : 'Submitting...',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} • $hour:$minute';
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 42,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No reports yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first person to report waste in your community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}