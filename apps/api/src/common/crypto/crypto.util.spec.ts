import { decrypt, encrypt, deserializePayload, serializePayload, generateEncryptionKey } from './crypto.util';

describe('crypto.util', () => {
  const key = generateEncryptionKey();

  it('encrypts and decrypts roundtrip', () => {
    const plain = 'secret-access-token-123';
    const payload = encrypt(plain, key);
    expect(payload.iv).toBeDefined();
    expect(payload.tag).toBeDefined();
    expect(payload.cipher).toBeDefined();
    expect(decrypt(payload, key)).toBe(plain);
  });

  it('serialize and deserialize payload roundtrip', () => {
    const plain = 'another-secret';
    const payload = encrypt(plain, key);
    const serialized = serializePayload(payload);
    const restored = deserializePayload(serialized);
    expect(decrypt(restored, key)).toBe(plain);
  });

  it('different iv per encryption', () => {
    const plain = 'same';
    const a = encrypt(plain, key);
    const b = encrypt(plain, key);
    expect(a.iv).not.toBe(b.iv);
    expect(a.cipher).not.toBe(b.cipher);
    expect(decrypt(a, key)).toBe(plain);
    expect(decrypt(b, key)).toBe(plain);
  });

  it('throws on wrong key', () => {
    const plain = 'secret';
    const payload = encrypt(plain, key);
    const wrongKey = generateEncryptionKey();
    expect(() => decrypt(payload, wrongKey)).toThrow();
  });

  it('throws on invalid key length', () => {
    const shortKey = Buffer.alloc(16).toString('base64');
    expect(() => encrypt('x', shortKey)).toThrow(/32 bytes/);
  });
});
