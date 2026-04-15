import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/send_email_otp_usecase.dart';

class PendingEmailSignup {
  const PendingEmailSignup({
    required this.fullName,
    required this.email,
    required this.password,
    required this.otpCode,
    required this.generatedAt,
    this.sendAttempt = 1,
  });

  final String fullName;
  final String email;
  final String password;
  final String otpCode;
  final DateTime generatedAt;
  final int sendAttempt;

  bool get isExpired =>
      DateTime.now().difference(generatedAt) > const Duration(minutes: 10);

  PendingEmailSignup copyWith({
    String? otpCode,
    DateTime? generatedAt,
    int? sendAttempt,
  }) {
    return PendingEmailSignup(
      fullName: fullName,
      email: email,
      password: password,
      otpCode: otpCode ?? this.otpCode,
      generatedAt: generatedAt ?? this.generatedAt,
      sendAttempt: sendAttempt ?? this.sendAttempt,
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.pendingSignup,
  });

  factory OtpVerificationScreen.forSignup({
    Key? key,
    required PendingEmailSignup pendingSignup,
  }) {
    return OtpVerificationScreen(
      key: key,
      email: pendingSignup.email,
      pendingSignup: pendingSignup,
    );
  }

  final String email;
  final PendingEmailSignup? pendingSignup;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final SendEmailOtpUseCase _sendEmailOtpUseCase = const SendEmailOtpUseCase();

  Timer? _ticker;
  PendingEmailSignup? _pendingSignup;
  int _secondsUntilResend = 0;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _pendingSignup = widget.pendingSignup;
    _updateResendWindow();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateResendWindow(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _updateResendWindow() {
    final pendingSignup = _pendingSignup;
    if (pendingSignup == null) {
      if (_secondsUntilResend != 0 && mounted) {
        setState(() => _secondsUntilResend = 0);
      }
      return;
    }

    final resendAt = pendingSignup.generatedAt.add(const Duration(seconds: 45));
    final remaining = resendAt.difference(DateTime.now()).inSeconds;
    final nextValue = remaining > 0 ? remaining : 0;

    if (!mounted || nextValue == _secondsUntilResend) {
      return;
    }

    setState(() => _secondsUntilResend = nextValue);
  }

  Future<void> _verifyOtp() async {
    final pendingSignup = _pendingSignup;
    if (pendingSignup == null) {
      _showSnack('OTP verification is not available in this flow.');
      return;
    }

    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      _showSnack('Enter the 6-digit code sent to your email.');
      return;
    }

    if (pendingSignup.isExpired) {
      _showSnack('This code expired. Request a new code.');
      return;
    }

    if (enteredOtp != pendingSignup.otpCode) {
      _showSnack('Incorrect OTP. Check the code and try again.');
      return;
    }

    setState(() => _isVerifying = true);

    firebase_auth.User? createdUser;
    var completed = false;

    try {
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: pendingSignup.email,
        password: pendingSignup.password,
      );

      createdUser = userCredential.user;
      if (createdUser == null) {
        throw StateError('Unable to create the account.');
      }

      try {
        await createdUser.updateDisplayName(pendingSignup.fullName);
      } catch (_) {
        // The Firestore profile remains the source of truth for the display name.
      }

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(createdUser.uid)
          .set({
        'id': createdUser.uid,
        'email': pendingSignup.email,
        'displayName': pendingSignup.fullName,
        'photoUrl': createdUser.photoURL ?? '',
        'phoneNumber': createdUser.phoneNumber ?? '',
        'role': UserRole.customer.value,
        'isProfileComplete': true,
        'emailOtpVerified': true,
        'emailOtpVerifiedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      completed = true;

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _showSnack(_signupMessageFor(e));
    } on FirebaseException catch (_) {
      _showSnack('Account setup failed. Please try again.');
    } catch (_) {
      _showSnack('Could not complete signup. Please try again.');
    } finally {
      if (!completed && createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          await firebase_auth.FirebaseAuth.instance.signOut();
        }
      }

      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    final pendingSignup = _pendingSignup;
    if (pendingSignup == null || _secondsUntilResend > 0 || _isResending) {
      return;
    }

    setState(() => _isResending = true);

    final newOtp = _sendEmailOtpUseCase.generateOtp();
    final result = await _sendEmailOtpUseCase.sendOtp(
      recipientEmail: pendingSignup.email,
      recipientName: pendingSignup.fullName,
      otp: newOtp,
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() => _isResending = false);
      _showSnack(result.message ?? 'Could not resend the verification code.');
      return;
    }

    setState(() {
      _isResending = false;
      _pendingSignup = pendingSignup.copyWith(
        otpCode: newOtp,
        generatedAt: DateTime.now(),
        sendAttempt: pendingSignup.sendAttempt + 1,
      );
      _secondsUntilResend = 45;
    });

    _showSnack('A new verification code was sent to ${pendingSignup.email}.');
  }

  String _signupMessageFor(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Sign in or reset the password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password signup is disabled for this Firebase project.';
      default:
        return e.message ?? 'Could not complete signup. Please try again.';
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pendingSignup = _pendingSignup;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPalette.parchment, AppPalette.canvas],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: pendingSignup == null
                        ? _UnsupportedFlow(theme: theme, email: widget.email)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Email verification',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Enter the 6-digit code sent to ${pendingSignup.email}.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppPalette.muted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppPalette.canvas,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppPalette.forest
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Verification code',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'The code expires 10 minutes after it is sent.',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppPalette.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                      onSubmitted: (_) {
                                        if (!_isVerifying) {
                                          _verifyOtp();
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Enter OTP',
                                        prefixIcon:
                                            Icon(Icons.lock_clock_outlined),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyOtp,
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Verify & Create Account'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed:
                                    (_secondsUntilResend > 0 || _isResending)
                                        ? null
                                        : _resendOtp,
                                child: _isResending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _secondsUntilResend > 0
                                            ? 'Resend in ${_secondsUntilResend}s'
                                            : 'Resend code',
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Attempt ${pendingSignup.sendAttempt}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppPalette.muted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsupportedFlow extends StatelessWidget {
  const _UnsupportedFlow({
    required this.theme,
    required this.email,
  });

  final ThemeData theme;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verification unavailable',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This OTP screen is only wired for email signup right now. Return and restart the flow for $email.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppPalette.muted,
          ),
        ),
      ],
    );
  }
}
