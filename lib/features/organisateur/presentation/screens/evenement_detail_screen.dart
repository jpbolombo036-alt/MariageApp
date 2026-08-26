import 'package:flutter/material.dart';

import 'event_detail_management_screen.dart';

class EvenementDetailScreen extends StatelessWidget {
  const EvenementDetailScreen({super.key, required this.weddingId});

  final int weddingId;

  @override
  Widget build(BuildContext context) {
    return EventDetailManagementScreen(weddingId: weddingId);
  }
}
