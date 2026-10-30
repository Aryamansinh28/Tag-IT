
import 'create_campaign_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key});

  String formatCampaignDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Date not specified';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view campaigns.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Campaigns',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (profileSnapshot.hasError) {
            return const Center(
              child: Text('Could not load your account profile.'),
            );
          }

          final role = profileSnapshot.data?.data()?['role'];
          final isOrganization = role == 'organization';

          return Column(
            children: [
              if (isOrganization)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateCampaignScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Campaign'),
                    ),
                  ),
                ),
              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('campaigns')
                      .where('status', isEqualTo: 'published')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load campaigns.'),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final campaigns = snapshot.data?.docs ?? [];

                    if (campaigns.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No campaigns available yet.\n'
                            'Check back soon!',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: campaigns.length,
                      itemBuilder: (context, index) {
                        final campaign = campaigns[index].data();
                        final campaignId = campaigns[index].id;

                        final participantCount =
                            (campaign['participantCount'] as num?)
                                    ?.toInt() ??
                                0;

                        final participantLimit =
                            (campaign['participantLimit'] as num?)
                                    ?.toInt() ??
                                0;

                        final isFull = participantLimit > 0 &&
                            participantCount >= participantLimit;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign['title']?.toString() ??
                                      'Cleanup Campaign',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  campaign['description']?.toString() ??
                                      'No description available.',
                                ),

                                const SizedBox(height: 8),

                                if (campaign['location'] != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          campaign['location'].toString(),
                                        ),
                                      ),
                                    ],
                                  ),

                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Date: ${formatCampaignDate(campaign['date'])}',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Participant count
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        participantLimit > 0
                                            ? 'Participants: $participantCount / $participantLimit'
                                            : 'Participants: $participantCount',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Join / Joined button
                                if (!isOrganization)
                                  StreamBuilder<
                                      DocumentSnapshot<
                                          Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('campaigns')
                                        .doc(campaignId)
                                        .collection('participants')
                                        .doc(uid)
                                        .snapshots(),
                                    builder: (context, participantSnapshot) {
                                      final alreadyJoined =
                                          participantSnapshot.data?.exists ??
                                              false;

                                      final isLoading =
                                          participantSnapshot.connectionState ==
                                              ConnectionState.waiting;

                                      return SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: isLoading ||
                                                  participantSnapshot.hasError ||
                                                  alreadyJoined ||
                                                  isFull
                                              ? null
                                              : () => joinCampaign(
                                                    context: context,
                                                    campaignId: campaignId,
                                                    uid: uid,
                                                  ),
                                          icon: Icon(
                                            alreadyJoined
                                                ? Icons.check_circle
                                                : Icons.group_add,
                                          ),
                                          label: Text(
                                            alreadyJoined
                                                ? 'Joined'
                                                : isFull
                                                    ? 'Campaign Full'
                                                    : 'Join Campaign',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
}

Future<void> joinCampaign({
  required BuildContext context,
  required String campaignId,
  required String uid,
}) async {
  final db = FirebaseFirestore.instance;
  final campaignRef = db.collection('campaigns').doc(campaignId);
  final participantRef =
      campaignRef.collection('participants').doc(uid);

  try {
    await db.runTransaction((transaction) async {
      final campaignSnapshot = await transaction.get(campaignRef);
      final participantSnapshot = await transaction.get(participantRef);

      if (!campaignSnapshot.exists) {
        throw Exception('This campaign no longer exists.');
      }

      if (participantSnapshot.exists) {
        throw Exception('You have already joined this campaign.');
      }

      final campaign = campaignSnapshot.data()!;
      final limit =
          (campaign['participantLimit'] as num?)?.toInt() ?? 0;
      final count =
          (campaign['participantCount'] as num?)?.toInt() ?? 0;

      if (limit > 0 && count >= limit) {
        throw Exception('Sorry, this campaign is full.');
      }

      transaction.set(participantRef, {
        'userId': uid,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(campaignRef, {
        'participantCount': count + 1,
      });
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You joined the campaign!'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
