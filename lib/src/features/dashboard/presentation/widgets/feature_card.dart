import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final String href;
  final IconData icon;
  final String imageSrc;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.href,
    required this.icon,
    required this.imageSrc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image portion
            SizedBox(
              height: 150,
              child: Image.asset(
                imageSrc,
                fit: BoxFit.cover,
                // Simple placeholder for image errors
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child:
                      Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                ),
              ),
            ),
            // Content portion
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(title, style: theme.textTheme.titleLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Spacer(),
            // Button portion
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton(
                onPressed: onTap,
                child: Text('Explore $title'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
