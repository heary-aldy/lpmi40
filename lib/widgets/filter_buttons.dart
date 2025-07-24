import 'package:flutter/material.dart';

class FilterButtons extends StatelessWidget {
  final VoidCallback onShowAll;
  final VoidCallback onShowFavorites;

  const FilterButtons({
    super.key,
    required this.onShowAll,
    required this.onShowFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onShowAll,
          child: const Text('Smart Search'),
        ),
        const SizedBox(width: 8.0),
        ElevatedButton(
          onPressed: onShowFavorites,
          child: const Text('Favorites'),
        ),
      ],
    );
  }
}
