# CreditSea Loan App

CreditSea is a Flutter loan-application demo backed by an Express REST API and MongoDB. A user can verify a phone number, set up or use a password, complete a profile, check loan eligibility, submit an application, follow its simulated status, and try a simulated EMI repayment.

> **Demo only:** This project does not issue real loans, move money, send credit-bureau inquiries, or calculate a real credit score. OTP is mocked by default. See [Demo behavior and limitations](#demo-behavior-and-limitations).

## Project structure

| Path | Purpose |
|---|---|
| `app/` | Flutter mobile client using GetX |
| `backend/` | Express API, MongoDB/Mongoose models, authentication and loan routes |

## Main app flow

1. A new user enters a mobile number and verifies the on-screen demo OTP.
2. The new user creates a password. Returning users can sign in with their phone number and password, or verify by OTP.
3. The user completes their profile, then chooses a loan purpose, amount, and tenure.
4. The app checks eligibility and displays the EMI estimate. Submitting creates an application and shows a confirmation with its application ID.
5. The user can see applications and status history in **My Loans**.
6. For a simulated loan that reaches **Disbursed**, the user can record demo EMI payments and see the demo balance and repayment history.

## Features

- Phone OTP registration and verification, password setup, and password login.
- JWT-authenticated API requests; passwords are stored as salted `scrypt` hashes.
- User profile with name, date of birth, gender, PAN, email, employment type, and monthly income.
- Loan calculator with an amount range of ₹5,000–₹5,00,000, tenure of 3–36 months, and a 12% annual interest estimate.
- Eligibility checks based on profile completion, age (21–60), employment type, monthly income (at least ₹15,000), simulated score (at least 600), EMI-to-income ratio, and loan amount-to-income ratio.
- Application confirmation and a list/detail view with status history.
- Simulated status progression: Submitted → Under Review → Approved/Rejected → Disbursed. Eligible applications are simulated as approved; ineligible applications are simulated as rejected.
- Demo credit score starts at 650 and increases by 5 for each demo repayment, up to 900. This is not a real bureau score.
- Demo repayment for disbursed applications updates only demo loan balances, receipts, and history. No payment is collected.
- Optional Firebase Cloud Messaging (FCM) integration for loan status updates. It remains disabled unless the app and backend have the corresponding private Firebase configuration.

## Requirements

- Node.js 18 or newer and npm.
- MongoDB (a local instance or MongoDB Atlas).
- Flutter SDK and Android tooling for Android builds. An Android emulator or device is needed to run the mobile app.

## Run the backend locally

From the repository root:

```powershell
cd backend
Copy-Item .env.example .env
npm install
npm start
```

Edit `backend/.env` and set at least:

| Variable | Purpose |
|---|---|
| `PORT` | API port; defaults to `5000` |
| `MONGO_URI` | MongoDB connection string |
| `JWT_SECRET` | Private signing secret for authentication tokens |

Other environment variables:

| Variable | Purpose |
|---|---|
| `OTP_PROVIDER` | `mock` by default; `msg91` requires MSG91 configuration |
| `EXPOSE_OTP` | Set to `true` for the demo OTP response/screen flow |
| `MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`, `MSG91_COUNTRY_CODE` | Private MSG91 settings when using real SMS |
| `ADMIN_KEY` | Secret for the manual loan-status admin endpoint; replace the example value |
| `FIREBASE_SERVICE_ACCOUNT` | Optional private Firebase service-account JSON used by the backend for FCM |

Never commit `backend/.env`, Firebase service-account credentials, or other secrets. The app's Android `google-services.json` is also excluded from Git.

When the backend starts, its health endpoint is available at `http://localhost:5000/` and returns a small JSON status response.

## Run the Flutter app

The Android/iOS platform folders are included. From the repository root:

```powershell
cd app
flutter pub get
flutter run
```

The default API URL is the deployed Render API (`https://loan-app-creditsea.onrender.com/api`) in `lib/core/constants.dart`. To use a local backend instead:

- Android emulator: use `http://10.0.2.2:5000/api`.
- Physical device: use the computer's LAN IP and ensure the phone and computer can reach each other.

To create a release APK:

```powershell
flutter build apk --release
```

Output: `app/build/app/outputs/flutter-apk/app-release.apk`.

## API overview

All routes below are relative to `/api`. Routes marked **Auth** require `Authorization: Bearer <JWT>`.

| Method | Route | Auth | Purpose |
|---|---|---:|---|
| `GET` | `/` | No | API health check (at the server root, not under `/api`) |
| `POST` | `/auth/send-otp` | No | Request a phone OTP |
| `POST` | `/auth/verify-otp` | No | Verify OTP; a new account receives a short-lived password-setup token |
| `POST` | `/auth/set-password` | No | Create the password after OTP verification |
| `POST` | `/auth/login` | No | Sign in with phone number and password |
| `GET` | `/user/profile` | Auth | Read the signed-in user's profile |
| `PUT` | `/user/profile` | Auth | Complete or update the profile |
| `PUT` / `DELETE` | `/user/push-token` | Auth | Register/remove a device's FCM token |
| `POST` | `/loans/eligibility` | Auth | Check eligibility for an amount and tenure |
| `POST` | `/loans/apply` | Auth | Submit a loan application |
| `GET` | `/loans` | Auth | List applications and advance simulated statuses |
| `GET` | `/loans/:id` | Auth | Read an application and advance its simulated status |
| `POST` | `/loans/:id/repay` | Auth | Record one simulated EMI; never charges money |
| `PATCH` | `/loans/:id/status` | Admin key | Manually set a status using the `x-admin-key` header |

## Deploy the backend to Render

Create a Web Service for this repository with `backend` as the root directory, `npm install` as the build command, and `npm start` as the start command. Configure the required environment variables in Render's environment settings. Keep secrets there rather than in source control. After a successful deployment, check the service's `/` health endpoint.

## Tests and checks

Backend tests:

```powershell
cd backend
npm test
```

Flutter static analysis:

```powershell
cd app
flutter analyze
```

## Demo behavior and limitations

- **OTP:** Mock mode is the default. The demo OTP is exposed for the assignment flow when `EXPOSE_OTP=true`; no SMS is sent in mock mode. MSG91 can be enabled separately with a configured provider account.
- **Loan status:** Status progression is simulated by elapsed time and is advanced when the client requests loan data. The mobile app polls while it is running; this is not a real underwriting or disbursement process.
- **Push notifications:** FCM is optional and requires private Firebase configuration on the client and backend. Status notifications are triggered when the backend advances or manually changes a status; there is no independent scheduled status worker, so status changes are not guaranteed to notify while the app is closed.
- **Repayments:** The “Record demo EMI” action writes a mock repayment to the database and updates a simulated balance and score. There is no Razorpay integration or actual payment.
- **Credit score:** The displayed score is an assignment simulation, not a financial or credit-bureau score.
- **Security/deployment:** Use strong private secrets for `JWT_SECRET`, `ADMIN_KEY`, database credentials, and provider credentials. Restrict database network access appropriately for your deployment.
- **Design:** The app uses the [Flutter assignment Figma](https://www.figma.com/design/BtqR1DM3MUBsk4b36s5Ob5/Flutter-Asssignment?node-id=0-1&p=f) as its visual reference.
