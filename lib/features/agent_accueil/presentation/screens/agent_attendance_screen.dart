import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/checkin/checkin_api.dart';
import '../../../../src/checkin/checkin_providers.dart';
import '../../../../src/dashboard/dashboard_api.dart';
import '../../../../src/dashboard/dashboard_providers.dart';
import '../../../../src/theme/app_colors.dart';
import '../widgets/attendance_stat_card.dart';

/// Écran « Présences » de l'espace AGENT_ACCUEIL (onglet Présences).
class AgentAttendanceScreen extends ConsumerStatefulWidget {
  const AgentAttendanceScreen({super.key, required this.weddingId});

  final int weddingId;

  @override
  ConsumerState<AgentAttendanceScreen> createState() =>
      _AgentAttendanceScreenState();
}

class _AgentAttendanceScreenState extends ConsumerState<AgentAttendanceScreen> {
  bool _loading = true;
  String? _error;
  Dashboard? _dashboard;

  /// Message affiché quand le tableau de bord est inaccessible au rôle
  /// (AGENT_ACCUEIL n'a pas la permission `DASHBOARD_VIEW`).
  String? _statsError;

  List<CheckInPresence> _present = const [];
  List<CheckInSearchHit> _hits = const [];
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.weddingId == 0) {
      setState(() {
        _loading = false;
        _error = 'Aucun événement assigné';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _statsError = null;
    });

    // 1) Présences : indispensable à cet écran et autorisé pour AGENT_ACCUEIL
    //    (`GET /api/checkins/event/{id}`). C'est ce qui doit décider du succès.
    List<CheckInPresence> present;
    try {
      present = await ref
          .read(checkInApiProvider)
          .listPresent(widget.weddingId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les présences';
      });
      return;
    }

    // 2) Statistiques : `GET /api/events/{id}/dashboard` exige DASHBOARD_VIEW,
    //    absente du rôle AGENT_ACCUEIL → 403 attendu. L'écran reste utilisable.
    Dashboard? dash;
    String? statsError;
    try {
      dash = await ref
          .read(dashboardApiProvider)
          .getForWedding(widget.weddingId);
    } catch (_) {
      statsError =
          'Statistiques du tableau de bord indisponibles pour votre rôle.';
    }

    if (!mounted) return;
    setState(() {
      _dashboard = dash;
      _present = present;
      _statsError = statsError;
      _loading = false;
    });
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty || widget.weddingId == 0) {
      setState(() => _hits = const []);
      return;
    }
    try {
      final hits = await ref.read(checkInApiProvider).searchGuests(widget.weddingId, q);
      if (!mounted) return;
      setState(() => _hits = hits);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recherche impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final p = AgentPalette.of(context);
    final a = _dashboard?.attendance;
    final cats = _dashboard?.categories ?? const <CategoryStats>[];
    final presentCount = _present.fold<int>(
      0,
      (sum, person) => sum + person.numberOfAttendees,
    );
    final expected = a?.expected;
    final checkedIn = a?.checkedIn ?? presentCount;

    return RefreshIndicator(
      onRefresh: _load,
      color: p.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _Header(palette: p, onRefresh: _load),
          const SizedBox(height: 18),
          _HeroCard(
            palette: p,
            checkedIn: checkedIn,
            expected: expected,
            remaining: a?.remaining,
            rate: a?.checkInRate,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AttendanceStatCard(
                icon: Icons.group_outlined,
                value: expected == null ? '—' : '$expected',
                label: 'Invités attendus',
              ),
              const SizedBox(width: 14),
              AttendanceStatCard(
                icon: Icons.how_to_reg_outlined,
                value: '$checkedIn',
                label: 'Invités présents',
              ),
            ],
          ),
          if (_statsError != null) ...[
            const SizedBox(height: 16),
            _StatsInfo(message: _statsError!),
          ],
          const SizedBox(height: 26),
          _SectionTitle(
            palette: p,
            icon: Icons.search,
            title: 'Recherche rapide',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            style: TextStyle(color: p.textPrimary, fontSize: 14),
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Nom ou téléphone de l’invité',
              hintStyle: TextStyle(color: p.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: p.textSecondary, size: 20),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer',
                      icon: Icon(Icons.close, size: 18, color: p.textSecondary),
                      onPressed: () => setState(() {
                        _query.clear();
                        _hits = const [];
                      }),
                    ),
              filled: true,
              fillColor: p.surface,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: p.primary, width: 1.4),
              ),
            ),
          ),
          if (_hits.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final hit in _hits) ...[
              _SearchHitTile(hit: hit, palette: p),
              const SizedBox(height: 8),
            ],
          ],
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 26),
            _CategoriesCard(categories: cats, palette: p),
          ],
          const SizedBox(height: 26),
          _SectionTitle(
            palette: p,
            icon: Icons.how_to_reg_outlined,
            title: 'Déjà présents',
            trailing: presentCount > 0 ? '$presentCount pers.' : null,
          ),
          const SizedBox(height: 12),
          if (_present.isEmpty)
            _EmptyState(
              palette: p,
              icon: Icons.event_busy_outlined,
              message:
                  'Aucune arrivée enregistrée pour le moment.\nScannez un QR code pour démarrer.',
            )
          else
            for (final person in _present) ...[
              _PresenceTile(person: person, palette: p),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
/// Bandeau d'information : statistiques du tableau de bord indisponibles.
class _StatsInfo extends StatelessWidget {
  const _StatsInfo({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: p.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte héro : progression circulaire des arrivées sur fond dégradé.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.palette,
    required this.checkedIn,
    this.expected,
    this.remaining,
    this.rate,
  });

  final AgentPalette palette;
  final int checkedIn;
  final int? expected;
  final int? remaining;
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final goal = expected;
    final ratio =
        (rate ??
                (goal == null || goal == 0 ? 0.0 : checkedIn / goal))
            .clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final onHero = Colors.white;
    final onHeroSoft = Colors.white.withValues(alpha: 0.88);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.primary, p.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 94,
            height: 94,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 94,
                  height: 94,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: AlwaysStoppedAnimation<Color>(onHero),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: onHero,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'présents',
                      style: TextStyle(color: onHeroSoft, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avancement des arrivées',
                  style: TextStyle(
                    color: onHeroSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$checkedIn',
                      style: TextStyle(
                        color: onHero,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    if (goal != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '/ $goal',
                        style: TextStyle(
                          color: onHeroSoft,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _caption(),
                  style: TextStyle(color: onHeroSoft, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _caption() {
    final left = remaining;
    if (left == null) return 'personnes déjà enregistrées';
    if (expected == null) return '$left personne(s) en attente';
    if (left == 0) return 'Toutes les personnes attendues sont arrivées 🎉';
    return '$left personne(s) encore attendue(s)';
  }
}

/// Titre de section avec icône et, en option, un compteur à droite.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.palette,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final AgentPalette palette;
  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Row(
      children: [
        Icon(icon, size: 18, color: p.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: TextStyle(
                color: p.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
/// Répartition attendus / présents par catégorie d'invités.
class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({required this.categories, required this.palette});

  final List<CategoryStats> categories;
  final AgentPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            palette: palette,
            icon: Icons.pie_chart_outline,
            title: 'Répartition par catégorie',
            trailing: '${categories.length}',
          ),
          const SizedBox(height: 4),
          Text(
            'Basé sur les RSVP confirmés',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          for (final c in categories) _categoryRow(c),
        ],
      ),
    );
  }

  Widget _categoryRow(CategoryStats cat) {
    final expected = cat.expectedAttendees;
    final accepted = cat.accepted;
    final rate = expected == 0 ? 0.0 : (accepted / expected).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cat.name.isEmpty ? 'Sans catégorie' : cat.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: '${(rate * 100).round()}%',
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                '$accepted / $expected',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: palette.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête de l'onglet Présences : titre, sous-titre et bouton rafraîchir.
class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.onRefresh});

  final AgentPalette palette;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Présences',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Suivi des arrivées en temps réel',
                style: TextStyle(color: p.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onRefresh(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Icon(Icons.refresh_rounded, color: p.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

/// Petite étiquette colorée (statut, table, boisson...).
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Pastille ronde affichant les initiales de l'invité.
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.background,
    required this.foreground,
  });

  final String name;
  final Color background;
  final Color foreground;

  /// Diamètre de la pastille.
  static const double size = 42;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    if (parts.length == 1) return first;
    return '$first${parts.last.substring(0, 1).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        _initials,
        style: TextStyle(
          color: foreground,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Résultat de recherche : avatar, nom, statut d'accès, restants et table.
class _SearchHitTile extends StatelessWidget {
  const _SearchHitTile({required this.hit, required this.palette});

  final CheckInSearchHit hit;
  final AgentPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final accent = hit.canCheckIn ? AppColors.success : p.textSecondary;
    final table = hit.tableName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _InitialsAvatar(
            name: hit.guestName,
            background: accent.withValues(alpha: 0.12),
            foreground: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit.guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: hit.canCheckIn ? 'Peut entrer' : 'Déjà traité',
                      color: accent,
                    ),
                    if (hit.remainingAttendees > 0)
                      _Chip(
                        label: '${hit.remainingAttendees} restant(s)',
                        color: p.primary,
                      ),
                    if (table != null && table.isNotEmpty)
                      _Chip(label: table, color: p.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Invité déjà présent : avatar, nom, heure d'arrivée, personnes, table, boisson.
class _PresenceTile extends StatelessWidget {
  const _PresenceTile({required this.person, required this.palette});

  final CheckInPresence person;
  final AgentPalette palette;

  String? _timeLabel(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final time = _timeLabel(person.lastCheckedInAt);
    final table = person.tableName;
    final drink = person.drinkChoice;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialsAvatar(
            name: person.guestName,
            background: AppColors.success.withValues(alpha: 0.12),
            foreground: AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        person.guestName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (time != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: '${person.numberOfAttendees} pers.',
                      color: AppColors.success,
                    ),
                    if (table != null && table.isNotEmpty)
                      _Chip(label: table, color: p.primary),
                    if (drink != null && drink.isNotEmpty)
                      _Chip(label: drink, color: p.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// État vide : icône discrète et message centré dans une carte.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.palette,
    required this.icon,
    required this.message,
  });

  final AgentPalette palette;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: p.textSecondary.withValues(alpha: 0.65)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vue d'erreur avec bouton de reprise.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AgentPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: p.danger, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}