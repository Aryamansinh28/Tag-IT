import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'campaign_screen.dart';

import 'report_screen.dart';
import 'login_screen.dart';
import 'feed_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tag IT",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Welcome section
            const Text(
              "Make your community cleaner.",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Report waste, track problems and take action.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 28),

            // Main Report Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Text(
                            "Spot waste?",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Capture a photo and report the location "
                      "so the community can take action.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ReportScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add_a_photo_outlined,
                        ),
                        label: const Text(
                          "Report Waste",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Explore Tag IT",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Feed + Map
            Row(
              children: [

                Expanded(
                  child: _ActionCard(
                    icon: Icons.people_outline,
                    title: "Community",
                    subtitle: "View reports",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const FeedScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _ActionCard(
                    icon: Icons.map_outlined,
                    title: "Waste Map",
                    subtitle: "Explore hotspots",
                  onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                     builder: (context) => const MapScreen(),
                     ),
                   );
                  },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Campaign Card
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CampaignScreen(),
    ),
  );
},
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.volunteer_activism_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Community Campaigns",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Join cleanup campaigns and "
                              "make an impact.",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Small mission statement
            Center(
              child: Text(
                "Small actions. Cleaner communities.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Reusable small action card
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Icon(
                icon,
                size: 30,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}