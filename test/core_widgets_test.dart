import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mariageplus_app/src/core/widgets/app_empty_state.dart';
import 'package:mariageplus_app/src/core/widgets/app_error_state.dart';

void main() {
  testWidgets('AppEmptyState affiche le titre et le message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'Vide',
            message: 'Aucun contenu',
            actionLabel: 'Ajouter',
            onAction: null,
          ),
        ),
      ),
    );
    expect(find.text('Vide'), findsOneWidget);
    expect(find.text('Aucun contenu'), findsOneWidget);
    expect(find.text('Ajouter'), findsNothing);
  });

  testWidgets('AppEmptyState affiche le bouton action quand fourni', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'Vide',
            message: 'Aucun contenu',
            actionLabel: 'Ajouter',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Ajouter'), findsOneWidget);
    await tester.tap(find.text('Ajouter'));
    expect(tapped, isTrue);
  });

  testWidgets('AppErrorState affiche le message et le bouton', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            message: 'Erreur',
            onRetry: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Erreur'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    expect(tapped, isTrue);
  });
}
