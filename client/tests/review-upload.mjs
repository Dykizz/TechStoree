// Local protocol checks; no real Cloudinary requests or credentials.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('..', import.meta.url));
const projectRequire = createRequire(path.join(root, 'package.json'));
const ts = projectRequire('typescript');
const signed = { uploadUrl: 'https://api.cloudinary.com/local-test/auto/upload'.replace('/local-test/', '/v1_1/local-test/'), signature: 'test-signature', timestamp: 1792936800, apiKey: 'test-public-key', folder: 'techstore/reviews' };
let fetchImpl;
let signature = signed;
let requests = 0;
function load(relative) {
  const source = fs.readFileSync(path.join(root, relative), 'utf8');
  const compiled = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.CommonJS } }).outputText;
  const moduleShim = { exports: {} };
  vm.runInNewContext(compiled, { module: moduleShim, exports: moduleShim.exports, URL, FormData,
    fetch: (...args) => { requests++; return fetchImpl(...args); },
    require(name) {
      if (name === './reviews') return { reviewRequest: async () => signature, safeReviewImage: (value) => value.startsWith('https://') };
      return projectRequire(name);
    },
  });
  return moduleShim.exports;
}
const { uploadReviewImage, reviewUploadError } = load('lib/review-upload.ts');
const file = new File(['test image bytes'], 'local.png', { type: 'image/png' });
const signal = new AbortController().signal;
let passed = 0;
async function test(name, action) { await action(); passed++; console.log('PASS ' + name); }
(async () => {
  await test('Invalid cloud name maps to a configuration message without exposing provider keys', async () => {
    fetchImpl = async () => ({ ok: false, status: 401, json: async () => ({ error: { message: 'Invalid cloud_name Root; test-public-key test-signature' } }) });
    await assert.rejects(uploadReviewImage(file, signal), (error) => error.message.includes('chưa được cấu hình đúng') && !error.message.includes('test-public-key') && !error.message.includes('test-signature'));
  });
  await test('Signed upload sends the exact signature fields and returns a valid secure image URL', async () => {
    fetchImpl = async (endpoint, init) => {
      assert.equal(endpoint.hostname, 'api.cloudinary.com');
      assert.equal(init.body.get('folder'), signed.folder);
      assert.equal(init.body.get('api_key'), signed.apiKey);
      assert.equal(init.body.get('timestamp'), String(signed.timestamp));
      assert.equal(init.body.get('signature'), signed.signature);
      assert.ok(init.body.get('file'));
      assert.equal(init.body.get('api_secret'), null);
      return { ok: true, json: async () => ({ resource_type: 'image', secure_url: 'https://res.cloudinary.com/local-test/image/upload/local.png' }) };
    };
    assert.equal(await uploadReviewImage(file, signal), 'https://res.cloudinary.com/local-test/image/upload/local.png');
  });
  await test('Network and invalid image errors offer actionable retry messages', async () => {
    fetchImpl = async () => { throw new TypeError('Failed to fetch'); };
    await assert.rejects(uploadReviewImage(file, signal), /kết nối mạng/);
    assert.ok(reviewUploadError(400, 'Invalid image file').includes('Không đọc được ảnh'));
    assert.ok(reviewUploadError(413, 'too large').includes('Ảnh quá lớn'));
    assert.ok(reviewUploadError(429).includes('đang bận'));
  });
  await test('Unexpected upload targets are refused before any external request', async () => {
    const before = requests;
    for (const url of ['https://foreign.example/v1_1/test/auto/upload', 'https://api.cloudinary.com.evil.test/v1_1/test/auto/upload', 'https://x:y@api.cloudinary.com/v1_1/test/auto/upload', 'https://api.cloudinary.com/v1_1/test/auto/upload?extra=1']) {
      signature = { ...signed, uploadUrl: url };
      await assert.rejects(uploadReviewImage(file, signal), /chưa sẵn sàng/);
    }
    signature = signed;
    assert.equal(requests, before);
  });
  await test('Non-image or non-secure success payload is not shown as an uploaded photo', async () => {
    for (const data of [{ resource_type: 'raw', secure_url: 'https://example.test/a' }, { resource_type: 'image', secure_url: 'http://example.test/a' }, {}]) {
      fetchImpl = async () => ({ ok: true, json: async () => data });
      await assert.rejects(uploadReviewImage(file, signal), /ảnh hợp lệ/);
    }
  });
  console.log(`${passed} upload protocol checks passed; no external upload performed by this test.`);
})().catch((error) => { console.error(error); process.exitCode = 1; });
