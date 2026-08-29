import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../src/theme/app_theme.dart';
import '../../../../src/wedding/wedding_api.dart';
import '../../../../src/wedding/wedding_providers.dart';

class EvenementCreateStepperScreen extends ConsumerStatefulWidget {
  const EvenementCreateStepperScreen({super.key});

  @override
  ConsumerState<EvenementCreateStepperScreen> createState() =>
      _EvenementCreateStepperScreenState();
}

class _EvenementCreateStepperScreenState extends ConsumerState<EvenementCreateStepperScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  final _nameController = TextEditingController();
  final _groomFirstNameController = TextEditingController();
  final _groomLastNameController = TextEditingController();
  final _brideFirstNameController = TextEditingController();
  final _brideLastNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _welcomeController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _groomFirstNameController.dispose();
    _groomLastNameController.dispose();
    _brideFirstNameController.dispose();
    _brideLastNameController.dispose();
    _descriptionController.dispose();
    _welcomeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
    });
    try {
      await ref.read(weddingApiProvider).create(CreateWeddingRequest(
            // `name` et `eventType` sont requis par l'API /api/events.
            name: _nameController.text.trim().isEmpty
                ? 'Événement'
                : _nameController.text.trim(),
            eventType: EventType.wedding,
            // Les 4 champs sont @NotBlank côté backend : on remplit avec les
            // prénoms/noms saisis, sinon valeur neutre non vide par sécurité.
            groomFirstName: _groomFirstNameController.text.trim().isEmpty
                ? _nameController.text.trim()
                : _groomFirstNameController.text.trim(),
            groomLastName: _groomLastNameController.text.trim().isEmpty
                ? 'Événement'
                : _groomLastNameController.text.trim(),
            brideFirstName: _brideFirstNameController.text.trim().isEmpty
                ? 'Invités'
                : _brideFirstNameController.text.trim(),
            brideLastName: _brideLastNameController.text.trim().isEmpty
                ? 'MariagePlus'
                : _brideLastNameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de créer l\'événement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          onPressed: _step > 0 ? () => setState(() => _step--) : () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, size: 22, color: scheme.onSurface),
        ),
        title: Text(
          _step == 0 ? 'Informations' : _step == 1 ? 'Détails' : 'Activités',
          style: AppTypography.cardTitle(color: scheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepper(scheme),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _buildStepContent(scheme),
                ),
              ),
            ),
            _buildActions(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          _stepIndicator(scheme, 0, 'Informations'),
          _stepLine(scheme, 0),
          _stepIndicator(scheme, 1, 'Détails'),
          _stepLine(scheme, 1),
          _stepIndicator(scheme, 2, 'Activités'),
        ],
      ),
    );
  }

  Widget _stepIndicator(ColorScheme scheme, int step, String label) {
    final active = _step == step;
    final completed = _step > step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active ? scheme.primary : completed ? scheme.primary : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: active ? scheme.primary : scheme.outline),
            ),
            child: Center(
              child: active
                  ? Text('${step + 1}', style: AppTypography.small(color: Colors.white).copyWith(fontWeight: FontWeight.w600))
                  : completed
                      ? Icon(Icons.check, size: 16, color: scheme.primary)
                      : Text('${step + 1}', style: AppTypography.small(color: scheme.onSurfaceVariant)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.small(
              color: active ? scheme.primary : scheme.onSurfaceVariant,
            ).copyWith(fontWeight: active ? FontWeight.w600 : FontWeight.w400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(ColorScheme scheme, int step) {
    final active = _step > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: active ? scheme.primary : scheme.outline.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildStepContent(ColorScheme scheme) {
    switch (_step) {
      case 0:
        return _buildStep1(scheme);
      case 1:
        return _buildStep2(scheme);
      case 2:
        return _buildStep3(scheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Nom de l\'événement *',
            hintText: 'Ex. Mariage de David & Grâce',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        _buildCoupleSection(scheme),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Lieu *',
            hintText: 'Ex. Pullman Grand Hôtel, Kinshasa',
            prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: scheme.onSurfaceVariant),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                style: AppTypography.body(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Date *',
                  hintText: _eventDate != null ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}' : 'JJ/MM/AAAA',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: scheme.onSurfaceVariant),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _eventDate = picked);
                },
                validator: (v) => _eventDate == null ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                readOnly: true,
                style: AppTypography.body(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Heure début *',
                  hintText: _startTime != null ? _startTime!.format(context) : 'HH:MM',
                  suffixIcon: Icon(Icons.access_time_outlined, size: 20, color: scheme.onSurfaceVariant),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Heure fin',
            hintText: _endTime != null ? _endTime!.format(context) : 'HH:MM',
            suffixIcon: Icon(Icons.access_time_outlined, size: 20, color: scheme.onSurfaceVariant),
          ),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _endTime ?? TimeOfDay.now(),
            );
            if (picked != null) setState(() => _endTime = picked);
          },
        ),
      ],
    );
  }

  Widget _buildCoupleSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Le couple',
          style: AppTypography.small().copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _groomFirstNameController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Prénom du marié',
            hintText: 'Ex. David',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _groomLastNameController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Nom du marié',
            hintText: 'Ex. Kasongo',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _brideFirstNameController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Prénom de la mariée',
            hintText: 'Ex. Grâce',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _brideLastNameController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Nom de la mariée',
            hintText: 'Ex. Mbuyi',
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _descriptionController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Détails de l\'événement',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _welcomeController,
          style: AppTypography.body(color: scheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Message de bienvenue',
            hintText: 'Optionnel',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildStep3(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 48, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Prêt à créer l\'événement ?',
                style: AppTypography.cardTitle(color: scheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vérifiez les informations avant de valider.',
                style: AppTypography.body(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ColorScheme scheme) {
    final isLast = _step == 2;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: _step > 0 ? 2 : 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E249E), Color(0xFF6B38D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitting ? null : (isLast ? _submit : () => setState(() => _step++)),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: _submitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                        : Text(
                            isLast ? 'Créer l\'événement' : 'Suivant',
                            style: AppTypography.button(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
