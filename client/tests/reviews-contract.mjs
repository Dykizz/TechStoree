// Local mocked contract checks for the review feature. No live uploads or DB writes.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('..', import.meta.url));
const projectRequire = createRequire(path.join(root, 'package.json'));
const ts = projectRequire('typescript');
const calls = [];
let backend = async () => { throw new Error('Unexpected backend request'); };
let sessionCode = 200;
let passed = 0;
const cache = new Map();
const server = {
  sameOrigin: (request) => !request.headers.get('origin') || request.headers.get('origin') === request.nextUrl.origin,
  backendApiRequest: (...args) => backend(...args),
};
function load(relative) {
  const filename = path.join(root, relative);
  if (cache.has(filename)) return cache.get(filename);
  const source = fs.readFileSync(filename, 'utf8');
  const compiled = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.CommonJS } }).outputText;
  const moduleShim = { exports: {} };
  vm.runInNewContext(compiled, {
    module: moduleShim, exports: moduleShim.exports, URL, URLSearchParams, Headers, Request, Response,
    require(name) {
      if (name === 'next/server') return { NextResponse: { json: (body, init) => Response.json(body, init) } };
      if (name.endsWith('/auth-server') || name === './auth-server') return server;
      if (name.endsWith('/customer-proxy') || name === './customer-proxy') return {
        customerProxy: async (request, endpoint, init) => {
          calls.push({ endpoint, init });
          return Response.json({ success: sessionCode < 400, data: sessionCode < 400 ? { reviewId: 1 } : null }, { status: sessionCode });
        },
      };
      if (name.startsWith('.')) return load(path.relative(root, path.resolve(path.dirname(filename), name)) + '.ts');
      return projectRequire(name);
    },
  });
  cache.set(filename, moduleShim.exports); return moduleShim.exports;
}
function req(url = '/api/reviews', body, origin = 'http://localhost:3000') {
  const request = new Request('http://localhost:3000' + url, { method: body === undefined ? 'GET' : 'POST', headers: { origin, 'Content-Type': 'application/json' }, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
  request.nextUrl = new URL(request.url); return request;
}
async function check(name, fn) { await fn(); console.log('PASS ' + name); passed++; }
const raw = { reviewId: 1, userId: 99, fullName: 'Nguyễn Văn An', username: 'private-user', email: 'private@example.test', phone: '0900000000', orderId: 12, orderCode: 'PRIVATE-12', orderItemId: 31, productId: 5, productName: 'Sản phẩm', rating: 4.5, comment: 'Nội dung thật', imageUrls: ['https://res.cloudinary.com/example/image/upload/test.jpg', 'javascript:alert(1)'], replyContent: 'Cảm ơn bạn', createdAt: '2026-10-23T00:00:00Z' };
const params = { params: Promise.resolve({ id: '5' }) };
(async () => {
  const helper = load('lib/reviews-server.ts');
  const review = load('lib/reviews.ts');
  await check('Public allowlist masks names and removes contact, user and order identifiers', () => {
    const safe = helper.publicReview(raw);
    for (const field of ['fullName', 'username', 'email', 'phone', 'userId', 'orderId', 'orderCode', 'orderItemId']) assert.equal(safe[field], undefined);
    assert.equal(safe.authorName, 'N***n'); assert.equal(safe.rating, 4.5);
    assert.equal(safe.imageUrls.length, 1); assert.equal(safe.replyContent, raw.replyContent);
  });
  await check('Half-star and pagination validation reject invalid/unsafe values', () => {
    assert.equal(helper.reviewId('../1'), null); assert.equal(helper.reviewId('2147483648'), null);
    assert.equal(helper.reviewQuery(req('/api/reviews?page=0')), null);
    assert.equal(helper.reviewQuery(req('/api/reviews?pageSize=101')), null);
    assert.equal(helper.reviewQuery(req('/api/reviews?rating=4.2'), true), null);
    assert.equal(helper.reviewQuery(req('/api/reviews?hasImages=maybe'), true), null);
    const valid = helper.reviewQuery(req('/api/reviews?rating=4.5&hasImages=true&page=2'), true);
    assert.equal(valid.get('rating'), '4.5'); assert.equal(valid.get('page'), '2');
  });
  await check('Create/edit operations reject foreign-origin writes before proxying', async () => {
    const before = calls.length;
    const response = await helper.saveReview(req('/api/reviews', { rating: 5, imageUrls: [], orderItemId: 31 }, 'https://foreign.example'));
    assert.equal(response.status, 403); assert.equal(calls.length, before);
  });
  await check('Save rejects invalid ratings, oversized comments and unsafe images', async () => {
    for (const payload of [{ rating: 4.2 }, { comment: 'x'.repeat(1001) }, { imageUrls: ['data:image/png;base64,x'] }, { imageUrls: Array(6).fill('https://example.test/a.png') }, { orderItemId: 0 }]) {
      const response = await helper.saveReview(req('/api/reviews', { rating: 5, imageUrls: [], orderItemId: 31, ...payload }));
      assert.equal(response.status, 400);
    }
  });
  await check('Create sends only the existing backend contract; no user/role assignment', async () => {
    await helper.saveReview(req('/api/reviews', { rating: 4.5, comment: '  Thật  ', imageUrls: [], orderItemId: 31, userId: 999, role: 'ADMIN' }));
    const call = calls.at(-1); const body = JSON.parse(call.init.body);
    assert.equal(call.endpoint, 'Reviews'); assert.equal(call.init.method, 'POST');
    assert.deepEqual(body, { rating: 4.5, comment: 'Thật', imageUrls: [], orderItemId: 31 });
  });
  await check('Edit uses PUT by review ID and cannot replace the order item', async () => {
    await helper.saveReview(req('/api/reviews/7', { rating: 3.5, comment: null, imageUrls: [], orderItemId: 999 }), 7);
    const call = calls.at(-1); assert.equal(call.endpoint, 'Reviews/7'); assert.equal(call.init.method, 'PUT');
    assert.equal(JSON.parse(call.init.body).orderItemId, undefined);
  });
  await check('Expiry uses original CreatedAt, including the exact 30-day boundary', () => {
    const start = Date.parse('2026-10-01T00:00:00Z');
    assert.equal(review.canEditReview({ createdAt: '2026-10-01T00:00:00Z' }, start + 30 * 86400000), true);
    assert.equal(review.canEditReview({ createdAt: '2026-10-01T00:00:00Z' }, start + 30 * 86400000 + 1), false);
    assert.equal(review.canEditReview({ createdAt: 'invalid' }), false);
  });
  await check('Anonymous private routes retain backend authentication denial', async () => {
    sessionCode = 401;
    for (const file of ['pending', 'my-reviews']) assert.equal((await load(`app/api/reviews/${file}/route.ts`).GET(req(`/api/reviews/${file}`))).status, 401);
    assert.equal((await helper.saveReview(req('/api/reviews', { rating: 5, imageUrls: [], orderItemId: 31 }))).status, 401);
    sessionCode = 200;
  });
  await check('Product endpoint returns masked reviews and real pagination only', async () => {
    backend = async (endpoint) => {
      assert.ok(endpoint.startsWith('Reviews/product/5?'));
      return { response: { ok: true, status: 200 }, body: { success: true, data: { items: [raw], meta: { page: 2, pageSize: 6, totalItems: 10, totalPages: 2 } } } };
    };
    const response = await load('app/api/reviews/product/[id]/route.ts').GET(req('/api/reviews/product/5?page=2&rating=4.5'), params);
    const value = await response.json(); assert.equal(value.data.meta.totalItems, 10);
    assert.equal(value.data.items[0].authorName, 'N***n'); assert.equal(value.data.items[0].email, undefined);
  });
  await check('Overview counts every rating across all pages without admin API access', async () => {
    let count = 0;
    backend = async (endpoint) => {
      assert.ok(endpoint.startsWith('Reviews/product/5?')); assert.ok(!endpoint.includes('admin'));
      const rating = Number(new URLSearchParams(endpoint.split('?')[1]).get('rating'));
      count++; return { response: { ok: true }, body: { success: true, data: { items: [], meta: { totalItems: rating === 5 ? 120 : rating === 4.5 ? 80 : 0 } } } };
    };
    const data = await (await load('app/api/reviews/product/[id]/summary/route.ts').GET(req('/api/reviews/product/5/summary'), params)).json();
    assert.equal(count, 9); assert.equal(data.data.totalReviews, 200); assert.equal(data.data.averageRating, 4.8);
    assert.equal(data.data.ratingDistribution['4.5'], 80);
  });
  await check('API failure produces an error instead of fake reviews or a zero score', async () => {
    backend = async () => { throw new Error('offline'); };
    assert.equal((await load('app/api/reviews/product/[id]/route.ts').GET(req('/api/reviews/product/5'), params)).status, 503);
    assert.equal((await load('app/api/reviews/product/[id]/summary/route.ts').GET(req('/api/reviews/product/5/summary'), params)).status, 503);
  });
  await check('Upload signature maps to the actual authenticated Media/signature API', async () => {
    const upload = load('app/api/reviews/upload-signature/route.ts');
    assert.equal((await upload.POST(req('/api/reviews/upload-signature', {}, 'https://foreign.example'))).status, 403);
    await upload.POST(req('/api/reviews/upload-signature', { folder: 'untrusted' }));
    assert.equal(calls.at(-1).endpoint, 'Media/signature');
    assert.equal(JSON.parse(calls.at(-1).init.body).folder, 'techstore/reviews');
  });
  console.log(`${passed} review contract checks passed. No real API mutations, Cloudinary upload or browser visual checks performed.`);
})().catch((error) => { console.error(error); process.exitCode = 1; });
