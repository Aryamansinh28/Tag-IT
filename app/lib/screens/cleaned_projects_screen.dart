import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CleanedProjectsScreen extends StatelessWidget {
  const CleanedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cleaned Projects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cleanups')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load cleaned projects.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final cleanups = snapshot.data?.docs ?? [];

          if (cleanups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cleaning_services_outlined,
                      size: 64,
                      color: primaryColor.withOpacity(0.75),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No cleaned projects yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Community cleanup submissions will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: cleanups.length,
            itemBuilder: (context, index) {
              final data = cleanups[index].data();
              final beforeImageUrl =
                  data['beforeImageUrl']?.toString() ?? '';
              final afterImageUrl = data['afterImageUrl']?.toString() ?? '';
              final description =
                  data['cleanupDescription']?.toString().trim() ?? '';
              final submittedAt = data['submittedAt'];
              final userEmail = data['userEmail']?.toString() ?? '';
              final status = data['status']?.toString() ?? 'submitted';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.volunteer_activism_outlined,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Community Cleanup',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatStatus(status),
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ProjectPhoto(
                              imageUrl: beforeImageUrl,
                              label: 'BEFORE',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProjectPhoto(
                              imageUrl: afterImageUrl,
                              label: 'AFTER',
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              submittedAt is Timestamp
                                  ? _formatTimestamp(submittedAt)
                                  : 'Recently submitted',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (userEmail.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 15,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Submitted by $userEmail',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatStatus(String status) {
    final normalized = status.trim();
    if (normalized.isEmpty) return 'Submitted';
    return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
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

class _ProjectPhoto extends StatelessWidget {
  final String imageUrl;
  final String label;

  const _ProjectPhoto({required this.imageUrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl.isEmpty
              ? Container(
                  height: 145,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined, size: 36),
                )
              : Image.network(
                  imageUrl,
                  height: 145,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 145,
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 145,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 36),
                  ),
                ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
            color: label == 'AFTER' ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
