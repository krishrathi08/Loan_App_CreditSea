class LoanModel {
  final String id, status;
  final num amount, emi, totalPayable, interestRate;
  final num amountPaid;
  final int tenureMonths;
  final String? purpose, rejectionReason;
  final DateTime createdAt;
  final List<StatusEntry> history;
  final List<RepaymentEntry> repayments;

  LoanModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.emi,
    required this.totalPayable,
    required this.interestRate,
    required this.tenureMonths,
    required this.createdAt,
    required this.history,
    required this.repayments,
    this.amountPaid = 0,
    this.purpose,
    this.rejectionReason,
  });

  factory LoanModel.fromJson(Map<String, dynamic> j) => LoanModel(
        id: j['_id'],
        status: j['status'],
        amount: j['amount'],
        emi: j['emi'] ?? 0,
        totalPayable: j['totalPayable'] ?? 0,
        interestRate: j['interestRate'] ?? 12,
        tenureMonths: j['tenureMonths'],
        purpose: j['purpose'],
        rejectionReason: j['rejectionReason'],
        createdAt: DateTime.parse(j['createdAt']).toLocal(),
        history: (j['history'] as List? ?? [])
            .map((e) => StatusEntry(e['status'], DateTime.parse(e['at']).toLocal()))
            .toList(),
        amountPaid: j['amountPaid'] ?? 0,
        repayments: (j['repayments'] as List? ?? [])
            .map((e) => RepaymentEntry(
                  amount: e['amount'],
                  paidAt: DateTime.parse(e['paidAt']).toLocal(),
                  balanceAfter: e['balanceAfter'],
                ))
            .toList(),
      );
}

class StatusEntry {
  final String status;
  final DateTime at;
  StatusEntry(this.status, this.at);
}

class RepaymentEntry {
  final num amount, balanceAfter;
  final DateTime paidAt;

  RepaymentEntry({
    required this.amount,
    required this.paidAt,
    required this.balanceAfter,
  });
}
