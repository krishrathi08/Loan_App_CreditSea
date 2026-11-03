const { promisify } = require('node:util');
const { randomBytes, scrypt, timingSafeEqual } = require('node:crypto');

const scryptAsync = promisify(scrypt);
const KEY_LENGTH = 64;

function isValidPassword(password) {
  return typeof password === 'string'
    && password.length >= 8
    && password.length <= 128
    && /[^A-Za-z0-9]/.test(password);
}

async function hashPassword(password) {
  const salt = randomBytes(16);
  const hash = await scryptAsync(password, salt, KEY_LENGTH);
  return `scrypt$${salt.toString('hex')}$${hash.toString('hex')}`;
}

async function verifyPassword(password, storedHash) {
  if (typeof storedHash !== 'string') return false;
  const [algorithm, saltHex, hashHex, ...extra] = storedHash.split('$');
  if (algorithm !== 'scrypt' || !saltHex || !hashHex || extra.length > 0) return false;

  const salt = Buffer.from(saltHex, 'hex');
  const expected = Buffer.from(hashHex, 'hex');
  if (salt.length !== 16 || expected.length !== KEY_LENGTH) return false;

  const actual = await scryptAsync(password, salt, KEY_LENGTH);
  return timingSafeEqual(expected, actual);
}

module.exports = { hashPassword, isValidPassword, verifyPassword };
