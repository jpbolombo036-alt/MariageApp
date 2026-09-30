import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../checkin/checkin_public_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'auth_controller.dart';
import 'auth_models.dart';
import 'widgets/auth_branding.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_text_field.dart';

/// Écran combiné connexion / inscription.
///
/// Reçoit le [AuthController] depuis le parent (qui le lit via Riverpod).
/// Le parent réagit à `isAuthenticated` pour ouvrir l'espace du rôle.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background =
        dark ? OrganizerColors.darkBackground : Colors.white;
    final card = dark ? OrganizerColors.darkSurface : AppColors.surface;
    final title = dark ? OrganizerColors.darkText : AppColors.primaryNavy;
    final muted =
        dark ? OrganizerColors.darkSecondary : AppColors.textSecondary;
    final border = dark ? OrganizerColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OrganizerColors.primary.withValues(alpha: dark ? 0.16 : 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryNavy.withValues(alpha: dark ? 0.35 : 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const AuthBranding(logoHeight: 84),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: dark ? 0.22 : 0.05),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _registerMode ? 'Créer un compte' : 'Connexion',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: title,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _registerMode
                                    ? 'Ouvrez l’espace de votre organisation.'
                                    : 'Accédez à vos événements et à votre équipe.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_registerMode) ...[
                                AuthTextField(
                                  label: 'Prénom',
                                  controller: _firstNameController,
                                  hint: 'Marie',
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                ),
                                const SizedBox(height: 14),
                                AuthTextField(
                                  label: 'Nom',
                                  controller: _lastNameController,
                                  hint: 'Dupont',
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                ),
                                const SizedBox(height: 14),
                                AuthTextField(
                                  label: 'Organisation',
                                  controller: _organizationNameController,
                                  hint: 'Maison des événements',
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                ),
                                const SizedBox(height: 14),
                              ],
                              AuthTextField(
                                label: 'E-mail',
                                controller: _emailController,
                                hint: 'vous@email.com',
                                prefixIcon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                validator: (v) => (v == null || !v.trim().contains('@'))
                                    ? 'Email invalide'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              AuthTextField(
                                label: 'Mot de passe',
                                controller: _passwordController,
                                hint: '8 caractères minimum',
                                prefixIcon: Icons.lock_outline,
                                obscure: true,
                                enableObscureToggle: true,
                                autocorrect: false,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submitting ? null : _submit(),
                                validator: (v) => (v == null || v.length < 8)
                                    ? 'Minimum 8 caractères'
                                    : null,
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: OrganizerColors.dangerBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: OrganizerColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              AuthPrimaryButton(
                                label: _registerMode ? "S'inscrire" : 'Se connecter',
                                loading: _submitting,
                                onPressed: _submitting ? null : _submit,
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => setState(() {
                                          _registerMode = !_registerMode;
                                          _error = null;
                                        }),
                                child: Text(
                                  _registerMode
                                      ? 'J’ai déjà un compte'
                                      : 'Créer un compte',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: OrganizerColors.primary,
                                  ),
                                ),
                              ),
                              const AuthDivider(),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _submitting
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const PublicRsvpPage(),
                                          ),
                                        ),
                                icon: Icon(Icons.mail_outline, size: 18, color: muted),
                                label: Text(
                                  'Répondre à une invitation',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const AuthFooter(),
                      ],
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
