import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final _api = ApiService();
  final _box = GetStorage();

  final loading = false.obs;
  final user = Rxn<UserModel>();
  final phone = ''.obs;
  final devOtp = ''.obs;
  final setupToken = ''.obs;

  bool get isLoggedIn => _box.read('token') != null;

  void _err(Object e) => Get.snackbar('Error', e.toString(),
      snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade50);

  Future<void> sendOtp(String p) async {
    loading.value = true;
    try {
      final res = await _api.post('/auth/send-otp', {'phone': p});
      phone.value = p;
      devOtp.value = res['devOtp']?.toString() ?? '';
      Get.toNamed('/otp');
    } catch (e) {
      _err(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> verifyOtp(String otp) async {
    loading.value = true;
    try {
      final res = await _api
          .post('/auth/verify-otp', {'phone': phone.value, 'otp': otp});
      if (res['needsPasswordSetup'] == true) {
        setupToken.value = res['setupToken']?.toString() ?? '';
        if (setupToken.value.isEmpty) {
          throw ApiException(
              'Password setup could not be started. Please request a new OTP.');
        }
        Get.offNamed('/create-password');
        return;
      }
      await _box.write('token', res['token']);
      user.value = UserModel.fromJson(res['user']);
      Get.offAllNamed(user.value!.profileComplete ? '/home' : '/profile-setup');
    } catch (e) {
      _err(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loginWithPassword(String p, String password) async {
    loading.value = true;
    try {
      final res =
          await _api.post('/auth/login', {'phone': p, 'password': password});
      await _startSession(res);
    } catch (e) {
      _err(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> setPassword(String password) async {
    loading.value = true;
    try {
      final res = await _api.post('/auth/set-password', {
        'setupToken': setupToken.value,
        'password': password,
      });
      setupToken.value = '';
      await _startSession(res);
    } catch (e) {
      _err(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> _startSession(Map<String, dynamic> res) async {
    await _box.write('token', res['token']);
    user.value = UserModel.fromJson(res['user']);
    Get.offAllNamed(user.value!.profileComplete ? '/home' : '/profile-setup');
  }

  /// Called from splash: keeps the user logged in until manual logout.
  Future<void> restoreSession() async {
    if (!isLoggedIn) return Get.offAllNamed('/login');
    try {
      final res = await _api.get('/user/profile');
      user.value = UserModel.fromJson(res['user']);
      Get.offAllNamed(user.value!.profileComplete ? '/home' : '/profile-setup');
    } catch (e) {
      if (!isLoggedIn) {
        Get.offAllNamed('/login'); // token expired
      } else {
        _err(e);
        Get.offAllNamed('/login');
      }
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await _api.get('/user/profile');
      user.value = UserModel.fromJson(res['user']);
    } catch (_) {}
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    loading.value = true;
    try {
      final res = await _api.put('/user/profile', data);
      user.value = UserModel.fromJson(res['user']);
      Get.offAllNamed('/home');
    } catch (e) {
      _err(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> logout() async {
    await _box.remove('token');
    user.value = null;
    Get.offAllNamed('/login');
  }
}
