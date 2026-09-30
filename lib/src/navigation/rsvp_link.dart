/// Extrait le jeton RSVP d'une route ou d'un lien `mariageplus://rsvp?token=`.
String? parseRsvpToken(String raw) {
  if (raw.isEmpty || raw == '/') return null;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;

  final queryToken = uri.queryParameters['token'];
  if (queryToken != null && queryToken.isNotEmpty) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    if (host == 'rsvp' || path.contains('rsvp') || uri.scheme == 'mariageplus') {
      return queryToken;
    }
  }

  final isRsvp = uri.host.toLowerCase() == 'rsvp' ||
      uri.pathSegments.any((segment) => segment.toLowerCase() == 'rsvp');
  if (!isRsvp || uri.pathSegments.isEmpty) return null;
  final last = uri.pathSegments.last;
  if (last.toLowerCase() == 'rsvp' || last.isEmpty) return null;
  return last;
}
