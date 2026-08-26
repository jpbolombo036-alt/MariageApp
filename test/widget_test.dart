import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mariageplus_app/main.dart';

void main() {
  testWidgets('MariagePlus app boots to auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: MariagePlusApp()));

    // Laisse la restauration asynchrone de session (lecture secure storage)
    // se terminer avant d'asserter l'affichage.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Sans session, le routeur affiche l'écran de connexion.
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}