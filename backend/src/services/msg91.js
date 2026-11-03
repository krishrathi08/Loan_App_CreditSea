const API_BASE = 'https://control.msg91.com/api/v5/otp';

function getConfig() {
  const { MSG91_AUTH_KEY, MSG91_TEMPLATE_ID, MSG91_COUNTRY_CODE = '91' } = process.env;
  if (!MSG91_AUTH_KEY || !MSG91_TEMPLATE_ID) {
    throw new Error('MSG91 is not configured');
  }
  return { authKey: MSG91_AUTH_KEY, templateId: MSG91_TEMPLATE_ID, countryCode: MSG91_COUNTRY_CODE };
}

async function request(path, params, options = {}) {
  const { authKey } = getConfig();
  const url = new URL(`${API_BASE}${path}`);
  url.searchParams.set('authkey', authKey);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  let response;
  try {
    response = await fetch(url, {
      ...options,
      signal: AbortSignal.timeout(15000),
      headers: { 'Content-Type': 'application/json', ...options.headers },
    });
  } catch {
    throw new Error('OTP provider is unavailable');
  }

  let result;
  try {
    result = await response.json();
  } catch {
    throw new Error('OTP provider returned an invalid response');
  }

  if (!response.ok || result.type === 'error') {
    throw new Error('OTP provider rejected the request');
  }
  return result;
}

async function sendOtp(phone) {
  const { templateId, countryCode } = getConfig();
  return request('', { template_id: templateId, mobile: `${countryCode}${phone}` }, {
    method: 'POST',
    body: '{}',
  });
}

async function verifyOtp(phone, otp) {
  const { countryCode } = getConfig();
  const result = await request('/verify', {
    mobile: `${countryCode}${phone}`,
    otp,
  });
  return result.type === 'success';
}

module.exports = { sendOtp, verifyOtp };
