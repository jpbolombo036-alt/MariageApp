import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Préférence d'apparence (système, clair, sombre), conservée hors session.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'mariageplus.theme_mode';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    try {
      final raw = await _storage.read(key: _key);
      final mode = _decode(raw);
      if (state != mode) state = mode;
    } catch (_) {
      // Stockage indisponible (tests) : on conserve le mode système.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: _encode(mode));
  }

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

/// Libellé affiché pour le mode courant.
String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'Clair',
      ThemeMode.dark => 'Sombre',
      ThemeMode.system => 'Système',
    };

/// Sélecteur clair / sombre / système.
Future<void> showThemeModePicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(themeModeProvider);
  final selected = await showModalBottomSheet<ThemeMode>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in ThemeMode.values)
            ListTile(
              title: Text(themeModeLabel(mode)),
              trailing: mode == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(ctx).pop(mode),
            ),
        ],
      ),
    ),
  );
  if (selected != null) {
    await ref.read(themeModeProvider.notifier).setMode(selected);
  }
}
