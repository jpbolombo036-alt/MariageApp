import 'package:flutter/material.dart';

import '../checkin/checkin_public_page.dart';
import '../theme/app_colors.dart';
import 'auth_controller.dart';
import 'auth_models.dart';
import 'widgets/auth_branding.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/floral_decorations.dart';

/// Écran combiné connexion / inscription, UI fidèle à la maquette premium.
///
/// Reçoit le [AuthController] depuis le parent (qui le lit via Riverpod).
/// Expose un formulaire à bascule login/register et rejoint la page d'accueil
/// automatiquement (le parent réagit à `isAuthenticated`).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _organizationNameController = TextEditingController();

  bool _registerMode = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final AuthController c = widget.controller;
    final AuthResult result;
    if (_registerMode) {
      result = await c.register(RegisterRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        organizationName: _organizationNameController.text.trim(),
      ));
    } else {
      result = await c.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = result.isSuccess ? null : (result.error ?? 'Une erreur est survenue');
    });
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              const Positioned.fill(child: FloralDecorations()),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        const AuthBranding(),
        const SizedBox(height: 40),
        _buildCard(),
        const SizedBox(height: 40),
        const AuthFooter(),
        const SizedBox(height: 4),
      ],
    );
  }

  // Carte blanche arrondie contenant le formulaire.
  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connexion',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primaryNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _registerMode
                  ? 'Créez votre compte organisateur'
                  : 'Connectez-vous à votre compte',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 30),
            if (_registerMode) ...[
              AuthTextField(
                label: 'Prénom',
                controller: _firstNameController,
                prefixIcon: Icons.person_outline,
                hint: 'Votre prénom',
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              AuthTextField(
                label: 'Nom',
                controller: _lastNameController,
                prefixIcon: Icons.person_outline,
                hint: 'Votre nom',
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              AuthTextField(
                label: 'Organisation',
                controller: _organizationNameController,
                prefixIcon: Icons.business_outlined,
                hint: 'Nom de votre organisation',
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
            ],

            AuthTextField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              hint: 'Entrez votre email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (v) =>
                  (v == null || !v.trim().contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 20),

            AuthTextField(
              label: 'Mot de passe',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline,
              hint: 'Entrez votre mot de passe',
              obscure: true,
              enableObscureToggle: true,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.length < 8) ? 'Minimum 8 caractères' : null,
              onFieldSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _ForgotPasswordLink(onPressed: _showForgotPassword),
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB00020), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: _registerMode ? "S'inscrire" : 'Se connecter',
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),

            const SizedBox(height: 24),
            const AuthDivider(),
            const SizedBox(height: 24),

            AuthSecondaryButton(
              label: _registerMode ? 'J’ai déjà un compte' : 'Créer un compte',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _submitting
                  ? null
                  : () => setState(() => _registerMode = !_registerMode),
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : _openPublicRsvp,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
              child: const Text('Répondre à une invitation'),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La réinitialisation de mot de passe sera bientôt disponible. '
          'Contactez votre organisateur pour la récupérer.',
        ),
      ),
    );
  }

  void _openPublicRsvp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PublicRsvpPage()),
    );
  }
}

/// Lien discret « Mot de passe oublié ? » aligné à droite, doré.
class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Mot de passe oublié ?',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}