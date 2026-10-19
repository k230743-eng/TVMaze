import 'package:flutter/material.dart';

import '../models/show.dart';
import '../screens/details_screen.dart';

class Poster extends StatelessWidget {
  final String? url;
  final double? width, height;
  const Poster(this.url, {super.key, this.width, this.height});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: width,
      height: height,
      child: url == null
          ? _placeholder()
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            ),
    ),
  );
  Widget _placeholder() => Container(
    color: const Color(0xFF252538),
    child: const Center(
      child: Icon(Icons.tv_rounded, color: Colors.white38, size: 36),
    ),
  );
}

class MessageView extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String buttonLabel;
  const MessageView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
    this.onRetry,
    this.buttonLabel = 'Try again',
  });
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton(
                  onPressed: onRetry,
                  child: Text(buttonLabel),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void openShow(BuildContext context, Show show) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => DetailsScreen(id: show.id)));

class ShowTile extends StatelessWidget {
  final Show show;
  final Widget? trailing;
  const ShowTile({super.key, required this.show, this.trailing});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    onTap: () => openShow(context, show),
    leading: Poster(show.image, width: 48, height: 72),
    title: Text(
      show.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${show.genres.isEmpty ? 'Genres unavailable' : show.genres.join(', ')}\nRating: ${show.rating?.toStringAsFixed(1) ?? 'Not rated'}',
      maxLines: 3,
    ),
    trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
  );
}
