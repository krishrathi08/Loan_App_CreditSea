import 'package:flutter/material.dart';

class AppConst {
  // Use 10.0.2.2 for Android emulator + local backend, or your deployed Render URL
  static const String baseUrl = 'https://loan-app-creditsea.onrender.com/api';
  static const Color primary = Color(0xFF0878F9);
  static const Color navy = Color(0xFF124F91);
  static const Color teal = Color(0xFF24C8B2);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color fieldBorder = Color(0xFFE6EAF0);
}

String inr(num v) {
  final s = v.round().toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final b = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) b.write(',');
    b.write(rest[i]);
  }
  return '₹$b,$last3';
}
