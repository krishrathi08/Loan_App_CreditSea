const User = require('../models/User');

let firebaseApp;
let configurationWarningLogged = false;

function getMessaging() {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccountJson) {
    if (!configurationWarningLogged) {
      console.warn('Push notifications are disabled; configure FIREBASE_SERVICE_ACCOUNT to enable FCM.');
      configurationWarningLogged = true;
    }
    return null;
  }

  if (!firebaseApp) {
    let serviceAccount;
    try {
      serviceAccount = JSON.parse(serviceAccountJson);
    } catch {
      throw new Error('FIREBASE_SERVICE_ACCOUNT must contain valid JSON');
    }
    if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT is missing required service-account fields');
    }
    const admin = require('firebase-admin');
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }

  return require('firebase-admin').messaging(firebaseApp);
}

async function sendToUser(userId, { title, body, loanId }) {
  const messaging = getMessaging();
  if (!messaging) return;

  const user = await User.findById(userId).select('pushTokens');
  const tokens = user?.pushTokens ?? [];
  if (tokens.length === 0) return;

  for (let index = 0; index < tokens.length; index += 500) {
    const batch = tokens.slice(index, index + 500);
    const response = await messaging.sendEachForMulticast({
      tokens: batch,
      notification: { title, body },
      data: { loanId },
    });
    const invalidTokens = response.responses
      .map((result, tokenIndex) => ({
        token: batch[tokenIndex],
        code: result.error?.code,
      }))
      .filter(({ code }) => [
        'messaging/invalid-registration-token',
        'messaging/registration-token-not-registered',
      ].includes(code))
      .map(({ token }) => token);

    if (invalidTokens.length > 0) {
      await User.updateOne({ _id: userId }, { $pull: { pushTokens: { $in: invalidTokens } } });
    }
    if (response.failureCount > 0) {
      console.error(`FCM delivery failed for ${response.failureCount} device(s).`);
    }
  }
}

module.exports = { sendToUser };
