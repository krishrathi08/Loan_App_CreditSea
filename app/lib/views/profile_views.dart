import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../core/constants.dart';
import '../widgets/creditsea_design.dart';

/// Used both for first-time profile setup and editing.
class ProfileFormView extends StatefulWidget {
  const ProfileFormView({super.key});
  @override
  State<ProfileFormView> createState() => _ProfileFormViewState();
}

class _ProfileFormViewState extends State<ProfileFormView> {
  final c = Get.find<AuthController>();
  final _key = GlobalKey<FormState>();
  late final name = TextEditingController(text: c.user.value?.name);
  late final email = TextEditingController(text: c.user.value?.email);
  late final pan = TextEditingController(text: c.user.value?.pan);
  late final income = TextEditingController(
    text: (c.user.value?.monthlyIncome ?? 0) > 0
        ? c.user.value!.monthlyIncome.toString()
        : '',
  );
  late DateTime? dob = c.user.value?.dob;
  late String gender = c.user.value?.gender ?? 'Male';
  late String employment = c.user.value?.employmentType ?? 'Salaried';

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pan.dispose();
    income.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          c.user.value?.profileComplete == true
              ? 'Edit Profile'
              : 'Personal Details',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _key,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: ApplicationProgress(activeStep: 0),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel('Full Name'),
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Gender'),
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: const InputDecoration(
                          hintText: 'Select your gender',
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => gender = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Date of Birth'),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: dob ?? DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => dob = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            hintText: 'DD - MM - YYYY',
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              size: 19,
                            ),
                          ),
                          child: Text(
                            dob == null
                                ? 'DD - MM - YYYY'
                                : DateFormat('dd - MM - yyyy').format(dob!),
                            style: TextStyle(
                              color:
                                  dob == null ? Colors.black45 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('PAN Number'),
                      TextFormField(
                        controller: pan,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          hintText: 'Enter your PAN number',
                          counterText: '',
                        ),
                        validator: (v) => RegExp(
                          r'^[A-Z]{5}[0-9]{4}[A-Z]$',
                        ).hasMatch((v ?? '').toUpperCase())
                            ? null
                            : 'Enter a valid PAN (ABCDE1234F)',
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Email ID'),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email ID',
                        ),
                        validator: (v) => GetUtils.isEmail(v ?? '')
                            ? null
                            : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Employment Type'),
                      DropdownButtonFormField<String>(
                        initialValue: employment,
                        decoration: const InputDecoration(
                          hintText: 'Select employment type',
                        ),
                        items: [
                          'Salaried',
                          'Self-Employed',
                          'Student',
                          'Unemployed',
                        ]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => employment = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Monthly Income'),
                      TextFormField(
                        controller: income,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter monthly income (₹)',
                        ),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                            ? null
                            : 'Enter monthly income',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Obx(
                  () => FilledButton(
                    onPressed: c.loading.value
                        ? null
                        : () {
                            if (!_key.currentState!.validate()) return;
                            if (dob == null) {
                              Get.snackbar(
                                'Missing',
                                'Select your date of birth',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            c.saveProfile({
                              'name': name.text.trim(),
                              'dob': dob!.toIso8601String(),
                              'gender': gender,
                              'pan': pan.text.trim().toUpperCase(),
                              'email': email.text.trim(),
                              'employmentType': employment,
                              'monthlyIncome': int.parse(income.text),
                            });
                          },
                    child: c.loading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
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

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Obx(() {
      final u = c.user.value;
      if (u == null) return const SizedBox();
      Widget row(IconData i, String l, String? v) => ListTile(
            leading: Icon(i, color: AppConst.primary),
            title: Text(
              l,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            subtitle: Text(
              v ?? '-',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          );
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppConst.primary,
              child: Text(
                (u.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              u.name ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                row(Icons.phone, 'Mobile', '+91 ${u.phone}'),
                row(Icons.email_outlined, 'Email', u.email),
                row(
                  Icons.cake_outlined,
                  'Date of birth',
                  u.dob == null
                      ? null
                      : DateFormat('dd MMM yyyy').format(u.dob!),
                ),
                row(Icons.person_outline, 'Gender', u.gender),
                row(Icons.credit_card, 'PAN', u.pan),
                row(Icons.work_outline, 'Employment', u.employmentType),
                row(
                  Icons.currency_rupee,
                  'Monthly income',
                  inr(u.monthlyIncome),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Get.to(() => const ProfileFormView()),
            icon: const Icon(Icons.edit),
            label: const Text('Edit profile'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Get.defaultDialog(
              title: 'Log out?',
              middleText: 'You will need to verify your number again.',
              textConfirm: 'Log out',
              textCancel: 'Cancel',
              onConfirm: c.logout,
            ),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    });
  }
}
