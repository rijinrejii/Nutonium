import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // Mock authentication logic (replace with real repository call)
        await Future.delayed(const Duration(seconds: 2));
        if (event.email == "test@test.com" && event.password == "password") {
          emit(AuthAuthenticated(user: event.email));
        } else {
          emit(const AuthError(message: "Invalid credentials"));
        }
      } catch (e) {
        emit(AuthError(message: e.toString()));
      }
    });

    on<SignupRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // Mock signup logic  (replace with real repository call)
        await Future.delayed(const Duration(seconds: 2));
        emit(AuthAuthenticated(user: event.email));
      } catch (e) {
        emit(AuthError(message: e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) {
      emit(AuthInitial());
    });
  }
}