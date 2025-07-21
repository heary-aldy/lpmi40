// lib/src/features/dashboard/presentation/widgets/personalized_content_widget.dart
// Personalized content recommendations and user-specific features

import 'package:flutter/material.dart';

class PersonalizedContentWidget extends StatelessWidget {
  final Map<String, dynamic> userPreferences;
  final List<String> recentActivity;

  const PersonalizedContentWidget({
    super.key,
    required this.userPreferences,
    required this.recentActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personalized for You',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentActivity.isNotEmpty) ...[
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...recentActivity.take(3).map((activity) => ListTile(
                    leading: const Icon(Icons.history, size: 16),
                    title: Text(activity),
                    dense: true,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
