import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/loan_controller.dart';
import '../core/constants.dart';
import '../models/loan_model.dart';
import 'profile_views.dart';
import '../widgets/creditsea_design.dart';

Color statusColor(String s) {
  switch (s) {
    case 'Approved':
    case 'Disbursed':
      return Colors.green;
    case 'Rejected':
      return Colors.red;
    case 'Under Review':
      return Colors.orange;
    default:
      return AppConst.primary;
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(['CreditSea', 'My Loans', 'Profile'][nav.index.value]),
          backgroundColor: Colors.transparent,
        ),
        body: IndexedStack(
          index: nav.index.value,
          children: const [HomeTab(), LoansTab(), ProfileTab()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: nav.index.value,
          onDestinationSelected: (i) => nav.index.value = i,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Loans',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final loan = Get.find<LoanController>();
    return RefreshIndicator(
      onRefresh: () async {
        await auth.refreshProfile();
        await loan.fetchLoans();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Obx(
            () => Text(
              'Hello, ${(auth.user.value?.name ?? '').split(' ').first} 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E6FD9), Color(0xFF0B3C8C)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulated credit score',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${auth.user.value?.creditScore ?? 650}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Demo estimate only; not a bureau score.',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Successful demo repayments add 5 points (max 900).',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConst.primary,
                    ),
                    onPressed: () => Get.toNamed('/calculator'),
                    child: const Text('Apply for a Loan'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent application',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(
            () => loan.loans.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No applications yet')),
                  )
                : LoanCard(loan: loan.loans.first),
          ),
        ],
      ),
    );
  }
}

class LoansTab extends StatelessWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoanController>();
    return Obx(() {
      if (c.loading.value && c.loans.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: c.fetchLoans,
        child: c.loans.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No loan applications yet')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: c.loans.length,
                itemBuilder: (_, i) => LoanCard(loan: c.loans[i]),
              ),
      );
    });
  }
}

class LoanCard extends StatelessWidget {
  final LoanModel loan;
  const LoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => LoanDetailView(loanId: loan.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inr(loan.amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${loan.tenureMonths} months • EMI ${inr(loan.emi)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(loan.createdAt),
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  loan.status,
                  style: TextStyle(
                    color: statusColor(loan.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor:
                    statusColor(loan.status).withValues(alpha: 0.12),
                side: BorderSide.none,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoanDetailView extends StatelessWidget {
  final String loanId;
  const LoanDetailView({super.key, required this.loanId});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoanController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: Obx(() {
        final loan = c.loans.firstWhereOrNull((l) => l.id == loanId);
        if (loan == null) return const Center(child: Text('Not found'));
        final rejected = loan.status == 'Rejected';
        final remainingBalance =
            (loan.totalPayable - loan.amountPaid).clamp(0, double.infinity);
        final steps = [
          'Submitted',
          'Under Review',
          rejected ? 'Rejected' : 'Approved',
          'Disbursed',
        ];
        final reached = steps.indexOf(loan.status);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ApplicationProgress(activeStep: 2),
            const SizedBox(height: 24),
            const Text(
              'Application Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Loan application no. #${loan.id}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Card(
              color: const Color(0xFFF9FBFD),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _kv('Amount', inr(loan.amount)),
                    _kv('Tenure', '${loan.tenureMonths} months'),
                    _kv('Interest', '${loan.interestRate}% p.a.'),
                    _kv('EMI', inr(loan.emi)),
                    _kv('Total payable', inr(loan.totalPayable)),
                    if (loan.purpose != null) _kv('Purpose', loan.purpose!),
                  ],
                ),
              ),
            ),
            if (loan.status == 'Disbursed') ...[
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFFF2F7FF),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Demo EMI repayment',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Simulation only. No payment provider is connected and no money will be charged.',
                      ),
                      const SizedBox(height: 10),
                      _kv('Paid in demo', inr(loan.amountPaid)),
                      _kv('Demo balance', inr(remainingBalance)),
                      if (remainingBalance > 0)
                        FilledButton.icon(
                          onPressed: c.loading.value
                              ? null
                              : () => Get.dialog(
                                    AlertDialog(
                                      title:
                                          const Text('Record demo repayment?'),
                                      content: Text(
                                        '${inr(loan.emi)} will be added to the demo repayment history. No money will be charged.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: Get.back,
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            Get.back();
                                            c.repay(loan.id);
                                          },
                                          child: const Text(
                                              'Confirm demo payment'),
                                        ),
                                      ],
                                    ),
                                  ),
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Record demo EMI'),
                        )
                      else
                        const Text(
                          'Demo balance fully repaid',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      if (loan.repayments.isNotEmpty) ...[
                        const Divider(),
                        const Text(
                          'Demo repayment history',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        for (final payment in loan.repayments.reversed)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(inr(payment.amount)),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(payment.paidAt),
                            ),
                            trailing: const Text('MOCK'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Application progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              _step(
                steps[i],
                done: i <= reached,
                last: i == steps.length - 1,
                color: steps[i] == 'Rejected' ? Colors.red : AppConst.primary,
                time: loan.history
                    .where((h) => h.status == steps[i])
                    .map((h) => h.at)
                    .firstOrNull,
              ),
            if (rejected && loan.rejectionReason != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Reason: ${loan.rejectionReason}'),
              ),
          ],
        );
      }),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.black54)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _step(
    String label, {
    required bool done,
    required bool last,
    required Color color,
    DateTime? time,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: last ? 0 : 9),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: done ? color.withValues(alpha: .65) : const Color(0xFFD8DDE4),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.task_alt : Icons.pending_outlined,
            size: 19,
            color: done ? color : Colors.black38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: done ? Colors.black87 : Colors.black38,
                  ),
                ),
                if (time != null)
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(time),
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
              ],
            ),
          ),
          if (done) Icon(Icons.check_circle, color: color, size: 18),
        ],
      ),
    );
  }
}
