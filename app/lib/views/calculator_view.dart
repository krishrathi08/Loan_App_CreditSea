import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/loan_controller.dart';
import '../core/constants.dart';
import '../widgets/creditsea_design.dart';

class CalculatorView extends StatelessWidget {
  const CalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoanController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for loan')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: ApplicationProgress(activeStep: 0),
            ),
            Expanded(
              child: Obx(
                () => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'We calculate your loan eligibility. Select your preferred loan amount and tenure.',
                        style: TextStyle(color: Colors.black54, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoBadge('Interest ${LoanController.rate}% p.a.'),
                          _infoBadge('No processing fee'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const _FieldLabel('Purpose of Loan'),
                      DropdownButtonFormField<String>(
                        initialValue: c.purpose.value,
                        decoration: const InputDecoration(
                          hintText: 'Select purpose of loan',
                        ),
                        items: [
                          'Personal',
                          'Medical',
                          'Education',
                          'Travel',
                          'Business',
                          'Home',
                        ]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) c.purpose.value = v;
                        },
                      ),
                      const SizedBox(height: 22),
                      _sliderTitle('Principal Amount', inr(c.amount.value)),
                      Slider(
                        value: c.amount.value,
                        min: 5000,
                        max: 500000,
                        divisions: 99,
                        onChanged: (v) {
                          c.amount.value = (v / 5000).round() * 5000.0;
                          c.eligible.value = null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹5,000', style: TextStyle(fontSize: 11)),
                            Text('₹5,00,000', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sliderTitle('Tenure', '${c.tenure.value} months'),
                      Slider(
                        value: c.tenure.value.toDouble(),
                        min: 3,
                        max: 36,
                        divisions: 33,
                        onChanged: (v) {
                          c.tenure.value = v.round();
                          c.eligible.value = null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('3 months', style: TextStyle(fontSize: 11)),
                            Text('36 months', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8FD3C8)),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Column(
                          children: [
                            _row('Principal Amount', inr(c.amount.value)),
                            _row('Monthly EMI', inr(c.emi)),
                            _row('Interest', inr(c.interest)),
                            const Divider(height: 20),
                            _row('Total Payable', inr(c.total), bold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (c.eligible.value != null) _eligibilityBox(c),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Obx(
                () => Column(
                  children: [
                    FilledButton(
                      onPressed: c.loading.value
                          ? null
                          : c.eligible.value == null
                              ? c.checkEligibility
                              : c.apply,
                      child: c.loading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              c.eligible.value == null
                                  ? 'Check Eligibility'
                                  : c.eligible.value == true
                                      ? 'Apply'
                                      : 'Apply Anyway',
                            ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: Get.back,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderTitle(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FA),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _infoBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppConst.fieldBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l),
            Text(
              v,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ],
        ),
      );

  Widget _eligibilityBox(LoanController c) {
    final ok = c.eligible.value == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.cancel,
                color: ok ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                ok ? 'You are eligible!' : 'Currently not eligible',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (!ok)
            ...c.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $r'),
              ),
            ),
        ],
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
