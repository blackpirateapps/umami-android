import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/auth_session.dart';
import 'dependencies.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AuthSession?> build() {
    return ref.watch(authRepositoryProvider).currentSession();
  }

  Future<void> login(LoginCommand command) async {
    state = const AsyncValue.loading();
    final useCase = ref.read(authenticateUserUseCaseProvider);
    final result = await useCase(command);
    state = result.when(
      failure: (failure) => AsyncValue.error(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
      success: AsyncValue.data,
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }
}
