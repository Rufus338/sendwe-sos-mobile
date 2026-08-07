/// A2 — Inscription patient (role forcé côté backend, section 9.A).

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../home/role_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _acceptTerms = false;
  bool _loading = false;
  String? _error;
  final Map<String, String> _fieldErrors = {};

  void _register() async {
    setState(() {
      _loading = true;
      _error = null;
      _fieldErrors.clear();
    });

    // Validation locale (section A2)
    if (_password.text.length < 8 || !_password.text.contains(RegExp(r'\d'))) {
      setState(() {
        _loading = false;
        _fieldErrors['password'] =
            'Le mot de passe doit contenir au moins 8 caractères et un chiffre';
      });
      return;
    }
    if (_password.text != _passwordConfirm.text) {
      setState(() {
        _loading = false;
        _fieldErrors['password_confirm'] =
            'Les mots de passe ne correspondent pas';
      });
      return;
    }
    if (!_acceptTerms) {
      setState(() {
        _loading = false;
        _fieldErrors['terms'] =
            'Veuillez accepter les conditions d\'utilisation';
      });
      return;
    }

    try {
      final data =
          await apiClient.post(
                '/auth/register',
                body: {
                  'full_name': _fullName.text.trim(),
                  'phone': _phone.text.trim(),
                  'password': _password.text,
                  'password_confirm': _passwordConfirm.text,
                },
              )
              as Map<String, dynamic>;

      await TokenStorage.save(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        role: data['role'] as String,
        userId: data['user_id'] as String,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        if (e.errorCode == 'PHONE_TAKEN') _fieldErrors['phone'] = e.message;
      });
    } catch (_) {
      setState(() => _error = 'Connexion impossible, vérifiez votre réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _fullName,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                errorText: _fieldErrors['full_name'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                hintText: '+243 ...',
                errorText: _fieldErrors['phone'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                errorText: _fieldErrors['password'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordConfirm,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                errorText: _fieldErrors['password_confirm'],
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acceptTerms,
              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              title: const Text('J\'accepte les conditions d\'utilisation'),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            if (_fieldErrors['terms'] != null)
              Text(
                _fieldErrors['terms']!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}
