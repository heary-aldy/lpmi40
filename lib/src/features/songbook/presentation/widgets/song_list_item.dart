import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onFavoritePressed;
  final VoidCallback onTap;

  const SongListItem({
    super.key,
    required this.song,
    required this.onFavoritePressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color? favoriteColor = song.isFavorite ? Colors.red.shade400 : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: song.isFavorite
                ? Colors.red.withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          )),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: favoriteColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: Text(song.number),
        ),
        title: Text(
          song.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: favoriteColor,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            song.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: favoriteColor ??
                (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          onPressed: onFavoritePressed,
          tooltip: 'Toggle Favorite',
        ),
        onTap: onTap,
      ),
    );
  }
}
