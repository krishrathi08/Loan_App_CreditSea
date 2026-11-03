class UserModel {
  final String id, phone;
  final String? name, gender, pan, email, employmentType;
  final DateTime? dob;
  final num monthlyIncome;
  final int creditScore;
  final bool profileComplete;

  UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.gender,
    this.pan,
    this.email,
    this.dob,
    this.employmentType,
    this.monthlyIncome = 0,
    this.creditScore = 650,
    this.profileComplete = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['_id'],
        phone: j['phone'],
        name: j['name'],
        gender: j['gender'],
        pan: j['pan'],
        email: j['email'],
        employmentType: j['employmentType'],
        dob: j['dob'] != null ? DateTime.parse(j['dob']).toLocal() : null,
        monthlyIncome: j['monthlyIncome'] ?? 0,
        creditScore: j['creditScore'] ?? 650,
        profileComplete: j['profileComplete'] ?? false,
      );

  UserModel withCreditScore(int score) => UserModel(
        id: id,
        phone: phone,
        name: name,
        gender: gender,
        pan: pan,
        email: email,
        dob: dob,
        employmentType: employmentType,
        monthlyIncome: monthlyIncome,
        creditScore: score,
        profileComplete: profileComplete,
      );
}
