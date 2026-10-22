import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Community",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .orderBy("timestamp", descending: true)
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
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Error loading reports:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return _EmptyFeed();
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              32,
            ),
            itemCount: reports.length,

            itemBuilder: (context, index) {
              final report =
                  reports[index].data()
                      as Map<String, dynamic>;

              final description =
                  report["description"] ??
                  "No description provided";

              final latitude =
                  report["latitude"];

              final longitude =
                  report["longitude"];

              final timestamp =
                  report["timestamp"];

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 16,
                ),

                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // Header
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
                                  "Waste Report",
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                SizedBox(height: 2),

                                Text(
                                  "Community report",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.more_horiz,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Location
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),

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
                                    "Reported location",
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    "$latitude, $longitude",
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

                      // Timestamp
                      Row(
                        children: [

                          Icon(
                            Icons.access_time_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            timestamp == null
                                ? "Submitting..."
                                : _formatTimestamp(
                                    timestamp,
                                  ),
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
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
          );
        },
      ),
    );
  }

  static String _formatTimestamp(
    Timestamp timestamp,
  ) {
    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, "0");
    final month =
        date.month.toString().padLeft(2, "0");

    final hour =
        date.hour.toString().padLeft(2, "0");

    final minute =
        date.minute.toString().padLeft(2, "0");

    return "$day/$month/${date.year} • $hour:$minute";
  }
}


class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

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
              "No reports yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Be the first person to report waste "
              "in your community.",
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