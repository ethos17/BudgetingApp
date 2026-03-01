import * as crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const AUTH_TAG_LENGTH = 16;
const KEY_LENGTH = 32;

export interface EncryptedPayload {
  iv: string;
  tag: string;
  cipher: string;
}

/**
 * Encrypts plaintext with AES-256-GCM.
 * @param plaintext - UTF-8 string to encrypt
 * @param keyBase64 - 32-byte key as base64 (or hex if keyHex is used)
 * @returns Object with iv, tag, cipher (all base64) for storage
 */
export function encrypt(plaintext: string, keyBase64: string): EncryptedPayload {
  const key = Buffer.from(keyBase64, 'base64');
  if (key.length !== KEY_LENGTH) {
    throw new Error('Encryption key must be 32 bytes (base64 decoded)');
  }
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  const enc = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return {
    iv: iv.toString('base64'),
    tag: tag.toString('base64'),
    cipher: enc.toString('base64'),
  };
}

/**
 * Decrypts a payload produced by encrypt().
 */
export function decrypt(payload: EncryptedPayload, keyBase64: string): string {
  const key = Buffer.from(keyBase64, 'base64');
  if (key.length !== KEY_LENGTH) {
    throw new Error('Encryption key must be 32 bytes (base64 decoded)');
  }
  const iv = Buffer.from(payload.iv, 'base64');
  const tag = Buffer.from(payload.tag, 'base64');
  const cipher = Buffer.from(payload.cipher, 'base64');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(tag);
  return decipher.update(cipher) + decipher.final('utf8');
}

/**
 * Serialize EncryptedPayload to a single string for DB storage.
 */
export function serializePayload(payload: EncryptedPayload): string {
  return JSON.stringify(payload);
}

/**
 * Deserialize from DB storage string back to EncryptedPayload.
 */
export function deserializePayload(serialized: string): EncryptedPayload {
  return JSON.parse(serialized) as EncryptedPayload;
}

/**
 * Generate a random 32-byte key (base64) for APP_ENCRYPTION_KEY.
 */
export function generateEncryptionKey(): string {
  return crypto.randomBytes(KEY_LENGTH).toString('base64');
}
