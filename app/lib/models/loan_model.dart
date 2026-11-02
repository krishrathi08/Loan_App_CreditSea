class LoanModel {
  final String id, status;
  final num amount, emi, totalPayable, interestRate;
  final int tenureMonths;
  final String? purpose, rejectionReason;
  final DateTime createdAt;
  final List<StatusEntry> history;

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
      );
}

class StatusEntry {
  final String status;
  final DateTime at;
  StatusEntry(this.status, this.at);
}
