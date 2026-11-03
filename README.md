# CreditSea Loan App (Flutter + Node.js + MongoDB)

Loan application app: mobile OTP login, profile, loan calculator, eligibility check, application submission and live status tracking.

## Structure
```
backend/   Node.js + Express + MongoDB (Mongoose) REST API
app/       Flutter app (GetX state management)
```

## Features
- New accounts verify their mobile number with OTP and create a password; returning users can sign in with mobile number and password or OTP (JWT, persistent login until manual logout)
- Profile: name, DOB, gender, PAN, email, employment, income
- Loan calculator (amount 5k–5L, tenure 3–36 months, EMI breakdown)
- Eligibility rules (age 21–60, income ≥ ₹15,000, credit score ≥ 600, EMI ≤ 50% income, amount ≤ 10× income)
- Status tracking: Submitted → Under Review → Approved/Rejected → Disbursed (auto-simulated by time, polled every 10s; admin override endpoint)
- Demo credit score: starts at 650 and increases by 5 for each recorded demo EMI (capped at 900); it is not a real bureau score
- Demo repayments: available for disbursed loans, update a demo balance/history only, and never charge money
- Push notifications: optional Firebase Cloud Messaging for loan status updates; the app and backend work with push disabled until Firebase is configured

## API
| Method | Endpoint | Description |
|---|---|---|
| POST | /api/auth/send-otp | Send OTP (demo: returned as `devOtp`) |
| POST | /api/auth/verify-otp | Verify OTP; new accounts receive a short-lived password-setup token |
| POST | /api/auth/set-password | Set a password after OTP verification, returns JWT |
| POST | /api/auth/login | Sign in with mobile number and password, returns JWT |
| GET/PUT | /api/user/profile | Get / save profile |
| PUT/DELETE | /api/user/push-token | Register / remove the signed-in device's FCM token |
| POST | /api/loans/eligibility | Check eligibility |
| POST | /api/loans/apply | Submit application |
| GET | /api/loans, /api/loans/:id | List / detail with status |
| PATCH | /api/loans/:id/status | Admin status change (`x-admin-key`) |
| POST | /api/loans/:id/repay | Record one simulated EMI and update the demo score (no real payment) |

## Run backend
```
cd backend && cp .env.example .env   # add MONGO_URI (MongoDB Atlas) and JWT_SECRET
npm install && npm start
```
Deploy on Render: New Web Service → root dir `backend` → build `npm install` → start `npm start` → add env vars.

## Run app
```
cd app
flutter create .          # generates android/ios folders (keeps lib/ and pubspec)
flutter pub get
# set baseUrl in lib/core/constants.dart
flutter run
flutter build apk --release
```
Add to `android/app/src/main/AndroidManifest.xml` (above `<application>`):
`<uses-permission android:name="android.permission.INTERNET"/>`

## Notes
- OTP uses mock mode locally by default; the demo OTP is shown on the OTP screen while `EXPOSE_OTP=true`. For real SMS, create and approve an MSG91 OTP template, set `OTP_PROVIDER=msg91`, and configure `MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`, and `MSG91_COUNTRY_CODE` in the backend environment. Set `EXPOSE_OTP=false` when using real SMS. Keep provider credentials private and never commit `.env`.
- Account passwords are scrypt-hashed by the backend and are never stored or returned in plaintext. Passwords must be at least 8 characters and contain a special character. OTP verification remains available as an alternative sign-in method.
- The mobile UI uses the [Figma assignment design](https://www.figma.com/design/BtqR1DM3MUBsk4b36s5Ob5/Flutter-Asssignment?node-id=0-1&p=f) as its visual reference. The existing phone-OTP and loan API flow is retained; password sign-in, email verification, and separate PAN verification are not implemented.
- Demo repayments, the corresponding credit-score changes, and repayment receipts are simulated assignment features; no real payment processor or credit bureau is contacted.
