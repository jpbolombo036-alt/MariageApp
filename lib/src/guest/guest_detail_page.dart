import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guest_api.dart';

class GuestDetailPage extends ConsumerWidget {
  const GuestDetailPage({super.key, required this.guest});

  final Guest guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(guest.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Prénom', guest.firstName),
          _row('Nom', guest.lastName),
          if (guest.email != null && guest.email!.isNotEmpty)
            _row('Email', guest.email!),
          if (guest.phone != null && guest.phone!.isNotEmpty)
            _row('Téléphone', guest.phone!),
          if (guest.address != null && guest.address!.isNotEmpty)
            _row('Adresse', guest.address!),
          _row('Accompagnants', '${guest.allowedCompanions ?? 0}'),
          _row('Actif', guest.active ? 'Oui' : 'Non'),
          if (guest.notes != null && guest.notes!.isNotEmpty)
            _row('Notes', guest.notes!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
