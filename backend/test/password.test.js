const test = require('node:test');
const assert = require('node:assert/strict');
const { hashPassword, isValidPassword, verifyPassword } = require('../src/utils/password');

test('password policy requires length and a special character', () => {
  assert.equal(isValidPassword('creditsea1!'), true);
  assert.equal(isValidPassword('short!'), false);
  assert.equal(isValidPassword('lettersOnly123'), false);
  assert.equal(isValidPassword(`a${'b'.repeat(127)}!`), false);
});

test('password hashes are salted and verify without storing plaintext', async () => {
  const password = 'creditsea1!';
  const firstHash = await hashPassword(password);
  const secondHash = await hashPassword(password);

  assert.notEqual(firstHash, secondHash);
  assert.equal(firstHash.includes(password), false);
  assert.equal(await verifyPassword(password, firstHash), true);
  assert.equal(await verifyPassword('wrong-password!', firstHash), false);
  assert.equal(await verifyPassword(password, 'invalid-hash'), false);
});
