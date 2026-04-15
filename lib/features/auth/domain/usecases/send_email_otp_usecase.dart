import 'dart:math';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailOtpSendResult {
  const EmailOtpSendResult({
    required this.isSuccess,
    this.message,
  });

  final bool isSuccess;
  final String? message;
}

class SendEmailOtpUseCase {
  const SendEmailOtpUseCase();

  static const String _smtpEmail =
      String.fromEnvironment('NUTONIUM_SMTP_EMAIL');
  static const String _smtpPassword =
      String.fromEnvironment('NUTONIUM_SMTP_APP_PASSWORD');
  static const String _senderName = String.fromEnvironment(
      'NUTONIUM_SMTP_SENDER_NAME',
      defaultValue: 'Nutonium');

  bool get isConfigured =>
      _smtpEmail.trim().isNotEmpty && _smtpPassword.trim().isNotEmpty;

  String generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<EmailOtpSendResult> sendOtp({
    required String recipientEmail,
    required String otp,
    String? recipientName,
  }) async {
    if (!isConfigured) {
      return const EmailOtpSendResult(
        isSuccess: false,
        message:
            'Email OTP is not configured. Copy smtp.env.example.json to smtp.env.json, add your Gmail app password, then run flutter run --dart-define-from-file=smtp.env.json.',
      );
    }

    final smtpServer = gmail(_smtpEmail, _smtpPassword);
    final greetingName = recipientName?.trim().isNotEmpty == true
        ? recipientName!.trim()
        : 'there';
    final message = Message()
      ..from = Address(_smtpEmail, _senderName)
      ..recipients.add(recipientEmail.trim())
      ..subject = 'Your Nutonium verification code'
      ..text = '''
Hello $greetingName,

Your Nutonium verification code is $otp.

This code expires in 10 minutes.

If you did not request this code, you can ignore this email.
''';

    try {
      await send(message, smtpServer);
      return const EmailOtpSendResult(isSuccess: true);
    } catch (_) {
      return const EmailOtpSendResult(
        isSuccess: false,
        message:
            'Could not send the verification code. Check the SMTP settings and try again.',
      );
    }
  }
}
