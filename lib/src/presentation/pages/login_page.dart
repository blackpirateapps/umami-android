import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../application/providers/auth_controller.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/auth_session.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    super.key,
    this.initialError,
  });

  final Object? initialError;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _endpointController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _endpointController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;
    final error = authState.error ?? widget.initialError;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ShadCard(
                title: Row(
                  children: [
                    Icon(LucideIcons.activity, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Text('Umami Analytics', style: theme.textTheme.h3),
                  ],
                ),
                description: const Text('Sign in to your Umami instance.'),
                footer: ShadButton(
                  width: double.infinity,
                  enabled: !loading,
                  leading: loading
                      ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primaryForeground,
                          ),
                        )
                      : const Icon(LucideIcons.logIn),
                  onPressed: _submit,
                  child: Text(loading ? 'Signing in' : 'Sign in'),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    if (error != null) ...[
                      ShadAlert.destructive(
                        icon: const Icon(LucideIcons.circleAlert),
                        title: const Text('Sign in failed'),
                        description: Text(_message(error)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text('Endpoint', style: theme.textTheme.small),
                    const SizedBox(height: 6),
                    ShadInput(
                      controller: _endpointController,
                      enabled: !loading,
                      keyboardType: TextInputType.url,
                      placeholder: const Text('https://analytics.example.com'),
                      leading: const Icon(LucideIcons.server),
                    ),
                    const SizedBox(height: 14),
                    Text('Username', style: theme.textTheme.small),
                    const SizedBox(height: 6),
                    ShadInput(
                      controller: _usernameController,
                      enabled: !loading,
                      keyboardType: TextInputType.emailAddress,
                      placeholder: const Text('admin'),
                      leading: const Icon(LucideIcons.user),
                    ),
                    const SizedBox(height: 14),
                    Text('Password', style: theme.textTheme.small),
                    const SizedBox(height: 6),
                    ShadInput(
                      controller: _passwordController,
                      enabled: !loading,
                      obscureText: _obscurePassword,
                      placeholder: const Text('Password'),
                      leading: const Icon(LucideIcons.lock),
                      trailing: SizedBox.square(
                        dimension: 24,
                        child: OverflowBox(
                          maxHeight: 28,
                          maxWidth: 28,
                          child: ShadIconButton(
                            iconSize: 18,
                            padding: const EdgeInsets.all(2),
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final command = LoginCommand(
      baseUrl: _endpointController.text,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    await ref.read(authControllerProvider.notifier).login(command);
  }

  String _message(Object error) {
    return error is Failure ? error.message : error.toString();
  }
}
