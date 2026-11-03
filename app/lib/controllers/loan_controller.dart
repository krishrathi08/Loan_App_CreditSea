import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/loan_model.dart';

class LoanController extends GetxController {
  final _api = ApiService();

  final amount = 50000.0.obs;
  final tenure = 12.obs;
  final purpose = 'Personal'.obs;
  final loans = <LoanModel>[].obs;
  final loading = false.obs;
  final eligible = Rxn<bool>();
  final reasons = <String>[].obs;
  Timer? _poll;

  static const rate = 12.0;

  double get emi {
    const r = rate / 12 / 100;
    final n = tenure.value;
    final p = amount.value;
    return p * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  double get total => emi.roundToDouble() * tenure.value;
  double get interest => total - amount.value;

  @override
  void onInit() {
    super.onInit();
    fetchLoans();
    // live status tracking
    _poll = Timer.periodic(
        const Duration(seconds: 10), (_) => fetchLoans(silent: true));
  }

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }

  Future<void> fetchLoans({bool silent = false}) async {
    if (!silent) loading.value = true;
    try {
      final res = await _api.get('/loans');
      loans.value =
          (res['loans'] as List).map((e) => LoanModel.fromJson(e)).toList();
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> checkEligibility() async {
    loading.value = true;
    try {
      final res = await _api.post('/loans/eligibility',
          {'amount': amount.value, 'tenureMonths': tenure.value});
      eligible.value = res['eligible'];
      reasons.value = List<String>.from(res['reasons'] ?? []);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
  }

  Future<void> repay(String loanId) async {
    loading.value = true;
    try {
      final result = await _api.post('/loans/$loanId/repay', {});
      final updatedLoan = LoanModel.fromJson(result['loan']);
      final loanIndex = loans.indexWhere((loan) => loan.id == loanId);
      if (loanIndex >= 0) loans[loanIndex] = updatedLoan;
      final auth = Get.find<AuthController>();
      final currentUser = auth.user.value;
      if (currentUser != null) {
        auth.user.value = currentUser.withCreditScore(result['creditScore']);
      }
      final payment = result['repayment'];
      Get.snackbar(
        'Demo repayment recorded',
        '${inr(payment['amount'])} recorded. No real money was charged.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
  }

  Future<void> apply() async {
    loading.value = true;
    try {
      final result = await _api.post('/loans/apply', {
        'amount': amount.value,
        'tenureMonths': tenure.value,
        'purpose': purpose.value,
      });
      final submittedLoan = LoanModel.fromJson(result['loan']);
      loans.removeWhere((loan) => loan.id == submittedLoan.id);
      loans.insert(0, submittedLoan);
      eligible.value = null;
      Get.back();
      Get.find<NavController>().index.value = 1;
      await Get.dialog<void>(
        AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          title: const Text('Application submitted'),
          content: Text(
            'Your application for ${inr(submittedLoan.amount)} was submitted successfully. '
            'You can track its status in My Loans.\n\n'
            'Application ID: ${submittedLoan.id}',
          ),
          actions: [
            FilledButton(
              onPressed: Get.back,
              child: const Text('View my loans'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
    }
  }
}

class NavController extends GetxController {
  final index = 0.obs;
}
