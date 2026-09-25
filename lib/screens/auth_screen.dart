import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Auth: Login/Signup toggle wired to [AuthService] (Phase 5).
/// Screens never touch firebase_auth directly.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscure = true;
  bool _busy = false;
  bool _googleBusy = false;
  bool _phoneMode = false;
  bool _phoneBusy = false;
  bool _codeSent = false;
  String? _verificationId;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _smsCode = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _smsCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthService>();
      if (_isLogin) {
        await auth.signIn(_email.text, _password.text);
      } else {
        await auth.signUp(
          _email.text,
          _password.text,
          displayName: _name.text,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      // Generic on purpose: never leak whether an email exists.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleBusy = true);
    try {
      await context.read<AuthService>().signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on AuthCancelledException {
      // User dismissed the picker: stay silent.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _sendCode() async {
    setState(() => _phoneBusy = true);
    try {
      await context.read<AuthService>().startPhoneSignIn(
            phone: _phone.text,
            onCodeSent: (vid) {
              if (!mounted) return;
              setState(() {
                _verificationId = vid;
                _codeSent = true;
              });
            },
            onError: (message) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
          );
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send code. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _phoneBusy = false);
    }
  }

  Future<void> _verifyCode() async {
    final vid = _verificationId;
    if (vid == null) return;
    setState(() => _phoneBusy = true);
    try {
      await context.read<AuthService>().confirmPhoneCode(
            verificationId: vid,
            smsCode: _smsCode.text,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _phoneBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login & Sign Up')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLogin ? 'Welcome back' : 'Create your account',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Manage expenses and stay on top of goals.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeTab(
                          label: 'Log in',
                          active: _isLogin,
                          onTap: () => setState(() => _isLogin = true),
                        ),
                      ),
                      Expanded(
                        child: _ModeTab(
                          label: 'Sign up',
                          active: !_isLogin,
                          onTap: () => setState(() => _isLogin = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_phoneMode)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Sign in with your phone number.',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                              hintText: '+237 6 XX XX XX XX',
                            ),
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Enter SMS code',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _smsCode,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'SMS code',
                                hintText: '123456',
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed:
                                _phoneBusy ? null : (_codeSent ? _verifyCode : _sendCode),
                            child: _phoneBusy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _codeSent ? 'Verify' : 'Send code',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                        if (!_isLogin)
                          TextField(
                            controller: _name,
                            textCapitalization:
                                TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Alex Johnson',
                            ),
                          ),
                        if (!_isLogin) const SizedBox(height: 12),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'alex.j@example.com',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscure = !_obscure,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Log in' : 'Create account',
                                ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed:
                              (_busy || _googleBusy) ? null : _signInWithGoogle,
                          child: _googleBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Continue with Google'),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Log in',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _phoneMode = !_phoneMode;
                    _codeSent = false;
                    _verificationId = null;
                  }),
                  child: Text(
                    _phoneMode ? 'Use email instead' : 'Use phone instead',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
