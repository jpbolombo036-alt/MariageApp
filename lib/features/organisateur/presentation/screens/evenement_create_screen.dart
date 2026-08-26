import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// NOTA : cet écran est désormais INUTILISÉ.
///
/// La création d'événement passe par [EvenementCreateStepperScreen] (ouvert
/// par le bouton `+` de la barre de navigation), qui collecte les prénoms /
/// noms du couple et remplit correctement le `CreateWeddingRequest`
/// (les 4 champs `@NotBlank` du backend).
///
/// Ce fichier est conservé uniquement pour compatibilité avec un éventuel
/// import résiduel ; il n'est référencé par aucun écran actif.
class EvenementCreateScreen extends ConsumerStatefulWidget {
  const EvenementCreateScreen({super.key});

  @override
  ConsumerState<EvenementCreateScreen> createState() =>
      _EvenementCreateScreenState();
}

class _EvenementCreateScreenState extends ConsumerState<EvenementCreateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un événement'),
        automaticallyImplyLeading: true,
      ),
      body: const Center(
        child: Text(
          'Cette page est remplacée par le stepper de création.',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}