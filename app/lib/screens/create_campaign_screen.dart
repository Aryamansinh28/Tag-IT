
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState
    extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantsController = TextEditingController();
  final _rewardController = TextEditingController();

  DateTime? _selectedDate;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );

    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a campaign date.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (profile.data()?['role'] != 'organization') {
        throw Exception(
          'Only organization accounts can create campaigns.',
        );
      }

      final participantLimit =
          int.parse(_participantsController.text.trim());

      await FirebaseFirestore.instance
          .collection('campaigns')
          .add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'participantLimit': participantLimit,
        'reward': _rewardController.text.trim(),
        'organizerId': user.uid,
        'organizerEmail': user.email,
        'participantCount': 0,
        'status': 'published',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign published successfully!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('CREATE CAMPAIGN ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create campaign: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Campaign')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Organize a cleaner community',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share the details so volunteers know how to participate.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Campaign title',
                hintText: 'e.g. Sunday Beach Cleanup',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter a campaign title.'
                      : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What will volunteers do?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter a description.'
                      : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Area, city or meeting point',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter the campaign location.'
                      : null,
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _selectedDate == null
                    ? 'Choose campaign date'
                    : 'Date: ${_selectedDate!.day}/'
                        '${_selectedDate!.month}/'
                        '${_selectedDate!.year}',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _participantsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum participants',
                hintText: 'e.g. 30',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final limit = int.tryParse(value?.trim() ?? '');
                if (limit == null || limit < 1) {
                  return 'Enter a positive whole number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _rewardController,
              decoration: const InputDecoration(
                labelText: 'Reward or incentive (optional)',
                hintText: 'e.g. Certificate, refreshments',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _createCampaign,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.campaign_outlined),
                label: Text(
                  _saving ? 'Publishing...' : 'Publish Campaign',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
