import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../core/constants.dart';
import '../widgets/creditsea_design.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.find<AuthController>().restoreSession(),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: ColoredBox(
          color: AppConst.navy,
          child: Center(child: CreditSeaLogo(onBlue: true, size: 32)),
        ),
      );
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final phone = TextEditingController();

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const _AuthHero(
                title: 'Flexible Loan Options',
                subtitle: 'Loans to cater to your financial needs',
                icon: Icons.account_balance_wallet_outlined,
                showLoanTypes: true,
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Welcome to CreditSea!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _FieldLabel('Mobile Number'),
                      Row(
                        children: [
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppConst.fieldBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🇮🇳  +91',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: phone,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Enter your mobile number',
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_box,
                            color: AppConst.primary,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'By continuing, you agree to our privacy policy and Terms & Conditions.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Obx(
                        () => FilledButton(
                          onPressed: c.loading.value
                              ? null
                              : () {
                                  if (phone.text.length != 10) {
                                    Get.snackbar(
                                      'Invalid',
                                      'Enter a 10-digit mobile number',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  c.sendOtp(phone.text);
                                },
                          child: c.loading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Request OTP'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            if (phone.text.length != 10) {
                              Get.snackbar(
                                  'Invalid', 'Enter a 10-digit mobile number',
                                  snackPosition: SnackPosition.BOTTOM);
                              return;
                            }
                            c.sendOtp(phone.text);
                          },
                          child: const Text('Existing User? Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final otp = TextEditingController();

  @override
  void dispose() {
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const _AuthHero(
                title: 'Instant Loan Approval',
                subtitle: 'Verify your number to continue',
                icon: Icons.fact_check_outlined,
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Enter OTP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Verify OTP sent to +91 ${c.phone.value}',
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Obx(
                        () => c.devOtp.value.isEmpty
                            ? const SizedBox.shrink()
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E5),
                                  border: Border.all(
                                    color: const Color(0xFFF2D68B),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Color(0xFF8A6700),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Demo OTP: ${c.devOtp.value}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          otp.text = c.devOtp.value,
                                      child: const Text('Autofill'),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const _FieldLabel('One-time password'),
                      TextField(
                        controller: otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          letterSpacing: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: '•  •  •  •  •  •',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Obx(
                        () => FilledButton(
                          onPressed: c.loading.value
                              ? null
                              : () {
                                  if (otp.text.length != 6) {
                                    Get.snackbar(
                                      'Invalid',
                                      'Enter the 6-digit OTP',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  c.verifyOtp(otp.text);
                                },
                          child: c.loading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Verify'),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () => c.sendOtp(c.phone.value),
                          child: const Text('Resend OTP'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showLoanTypes;

  const _AuthHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.showLoanTypes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 315,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15589B), AppConst.navy],
        ),
      ),
      child: Column(
        children: [
          const CreditSeaLogo(onBlue: true, size: 24),
          const Spacer(),
          if (showLoanTypes)
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: const [
                _LoanTypeIcon(Icons.directions_car_outlined),
                _LoanTypeIcon(Icons.two_wheeler_outlined),
                _LoanTypeIcon(Icons.laptop_outlined),
                _LoanTypeIcon(Icons.phone_android_outlined),
              ],
            )
          else
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageDot(),
              SizedBox(width: 5),
              _PageDot(),
              SizedBox(width: 5),
              _PageDot(active: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoanTypeIcon extends StatelessWidget {
  final IconData icon;
  const _LoanTypeIcon(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 25),
      );
}

class _PageDot extends StatelessWidget {
  final bool active;
  const _PageDot({this.active = false});

  @override
  Widget build(BuildContext context) => Container(
        width: active ? 16 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 1 : .45),
          borderRadius: BorderRadius.circular(10),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
}
