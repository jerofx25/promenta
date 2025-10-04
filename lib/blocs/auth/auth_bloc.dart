import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart' as bloc_concurrency;

import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted, transformer: bloc_concurrency.droppable());
    on<AuthSignInRequested>(_onSignInRequested,
        transformer: bloc_concurrency.droppable());
    on<AuthRegisterRequested>(_onRegisterRequested,
        transformer: bloc_concurrency.droppable());
    on<AuthSignOutRequested>(_onSignOutRequested,
        transformer: bloc_concurrency.droppable());
    on<_AuthStatusChanged>(_onStatusChanged);
    on<_AuthProfileChanged>(_onProfileChanged);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSub?.cancel();
    _authSub = _authRepository.authStateChanges().listen((isAuth) {
      add(_AuthStatusChanged(isAuth));
    });

    await _profileSub?.cancel();
    _profileSub = _authRepository.currentUserProfile().listen((profile) {
      add(_AuthProfileChanged(profile));
    });
  }

  Future<void> _onSignInRequested(
      AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthFlowStatus.loading));
    try {
      await _authRepository.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      // Streams reaccionarán y actualizarán el estado
    } catch (e) {
      emit(state.copyWith(status: AuthFlowStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthFlowStatus.loading));
    try {
      await _authRepository.registerWithEmailAndPassword(
        event.email,
        event.password,
        event.displayName,
      );
    } catch (e) {
      emit(state.copyWith(status: AuthFlowStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthFlowStatus.loading));
    try {
      await _authRepository.signOut();
    } catch (e) {
      emit(state.copyWith(status: AuthFlowStatus.failure, error: e.toString()));
    }
  }

  void _onStatusChanged(_AuthStatusChanged event, Emitter<AuthState> emit) {
    final next = event.isAuthenticated
        ? state.copyWith(authenticated: true)
        : state.copyWith(authenticated: false, profile: null);
    emit(next);
  }

  void _onProfileChanged(_AuthProfileChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(profile: event.profile));
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _profileSub?.cancel();
    return super.close();
  }
}
