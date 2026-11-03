import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/api_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  final _api = ApiService();
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();

      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notifications were not permitted by the user.');
        return;
      }

      // FCM Admin multicast targets registration tokens, not Firebase Installation IDs.
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
      // ignore: deprecated_member_use
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (value) => unawaited(_registerToken(value)),
        onError: (Object error) =>
            debugPrint('FCM token refresh failed: $error'),
      );
      _messageSubscription = FirebaseMessaging.onMessage.listen(_showMessage);
      _openedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _handleOpened(initialMessage);
      _initialized = true;
    } on FirebaseException catch (error) {
      debugPrint('Push notifications are not configured: ${error.message}');
    } catch (error) {
      debugPrint('Push notification initialization failed: $error');
    }
  }

  Future<void> unregister() async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.delete('/user/push-token', {'token': token});
      }
    } catch (error) {
      debugPrint('Could not unregister the push token: $error');
    }
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    _initialized = false;
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.put('/user/push-token', {'token': token});
    } catch (error) {
      debugPrint('Could not register the push token: $error');
    }
  }

  void _showMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Loan update';
    final body =
        message.notification?.body ?? 'Your loan application has an update.';
    Get.snackbar(title, body, snackPosition: SnackPosition.TOP);
  }

  void _handleOpened(RemoteMessage message) {
    Get.offNamed('/home');
  }
}
