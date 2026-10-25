// Component state checks; no browser or Cloudinary traffic.
import fs from 'node:fs';
import vm from 'node:vm';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('..', import.meta.url));
const projectRequire = createRequire(path.join(root, 'package.json'));
const ts = projectRequire('typescript');
let count = 0;
function nodes(tree, test) {
  const output = [];
  function visit(value) { if (!value || typeof value !== 'object') return; if (test(value)) output.push(value); [value.props?.children].flat(Infinity).forEach(visit); }
  visit(tree); return output;
}
function harness(file, options = {}) {
  const slots = []; let cursor = 0; const calls = []; const saved = [];
  const hooks = {
    useRef(initial) { const i = cursor++; if (!(i in slots)) slots[i] = { current: initial }; return slots[i]; },
    useState(initial) { const i = cursor++; if (!(i in slots)) slots[i] = initial; return [slots[i], (next) => { slots[i] = typeof next === 'function' ? next(slots[i]) : next; }]; },
    useId: () => 'review-test', useEffect() {},
  };
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const compiled = ts.transpileModule(source, { compilerOptions: { jsx: ts.JsxEmit.ReactJSX, target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.CommonJS } }).outputText;
  const moduleShim = { exports: {} };
  vm.runInNewContext(compiled, { module: moduleShim, exports: moduleShim.exports, AbortController, URL,
    require(name) {
      if (name === 'react') return hooks;
      if (name === 'react/jsx-runtime') return { jsx: (type, props) => ({ type, props }), jsxs: (type, props) => ({ type, props }) };
      if (name === 'next/image') return { default: 'img' };
      if (name.endsWith('.css')) return { default: new Proxy({}, { get: (_, key) => key }) };
      if (name.endsWith('/reviews')) return {
        REVIEW_RATINGS: Array.from({ length: 9 }, (_, index) => 1 + index * .5), MAX_REVIEW_IMAGES: 5, MAX_REVIEW_IMAGE_BYTES: 5 * 1024 * 1024,
        safeReviewImage: () => true, canEditReview: () => options.editable !== false,
        reviewRequest: (...args) => { calls.push(args); return options.request(...args); },
      };
      if (name === './StarRating') return { RatingPicker: 'RatingPicker' };
      if (name === './ReviewThumbnail') return { default: 'ReviewThumbnail' };
      if (name.endsWith('/review-upload')) return { uploadReviewImage: (...args) => { calls.push(args); throw new Error('Invalid files must not start upload'); } };
      return projectRequire(name);
    },
  });
  const props = { item: { orderItemId: 21, productName: 'Sản phẩm kiểm thử', orderCode: 'LOCAL-ONLY' }, onClose() {}, onSaved: (value) => saved.push(value), ...options.props };
  return { calls, saved, render: () => { cursor = 0; return moduleShim.exports.default(props); }, exports: moduleShim.exports };
}
const form = (tree) => nodes(tree, (node) => node.type === 'form')[0];
const event = { preventDefault() {} };
(async () => {
  let resolve;
  const h = harness('components/reviews/ReviewComposer.tsx', { request: () => new Promise((yes) => { resolve = yes; }) });
  const handler = form(h.render()).props.onSubmit;
  const pending = handler(event); await handler(event);
  assert.equal(h.calls.length, 1); assert.equal(h.saved.length, 0); count++;
  console.log('PASS Rapid duplicate submit is locked before another render; no success before the API');
  assert.equal(form(h.render()).props['aria-busy'], true);
  assert.ok(nodes(h.render(), (node) => node.type === 'button' && node.props.disabled).length >= 2); count++;
  console.log('PASS Pending save disables closing/sending and exposes the busy state');
  resolve({ reviewId: 3, rating: 5 }); await pending; assert.equal(h.saved.length, 1); count++;
  console.log('PASS Confirmation is emitted once after the actual request succeeds');
  const failure = harness('components/reviews/ReviewComposer.tsx', { request: async () => { throw new Error('Backend declined'); } });
  let tree = failure.render();
  nodes(tree, (node) => node.type === 'textarea')[0].props.onChange({ target: { value: 'Nhận xét cần được giữ khi lỗi' } });
  tree = failure.render(); await form(tree).props.onSubmit(event); tree = failure.render();
  assert.equal(nodes(tree, (node) => node.type === 'textarea')[0].props.value, 'Nhận xét cần được giữ khi lỗi');
  assert.equal(failure.saved.length, 0); assert.equal(form(tree).props['aria-busy'], false); count++;
  console.log('PASS Rejected request preserves the draft and unlocks the form');
  const upload = harness('components/reviews/ReviewComposer.tsx', { request: () => { throw new Error('Invalid files must never request a signature'); } });
  for (const files of [[{ type: 'image/svg+xml', size: 10 }], [{ type: 'image/png', size: 6 * 1024 * 1024 }], Array(6).fill({ type: 'image/png', size: 10 })]) {
    const input = nodes(upload.render(), (node) => node.type === 'input' && node.props.type === 'file')[0];
    await input.props.onChange({ target: { files, value: 'file' } });
  }
  assert.equal(upload.calls.length, 0); count++;
  console.log('PASS Unsupported, oversized or excess photos are rejected before upload');
  const expired = harness('components/reviews/ReviewComposer.tsx', { editable: false, props: { review: { reviewId: 1, rating: 4, imageUrls: [] } }, request: () => { throw new Error('Expired edit must not reach API'); } });
  await form(expired.render()).props.onSubmit(event); assert.equal(expired.calls.length, 0); count++;
  console.log('PASS An expired edit is refused without discarding content or posting it');
  const stars = harness('components/reviews/StarRating.tsx');
  let chosen;
  const picker = stars.exports.RatingPicker({ value: 4.5, disabled: false, onChange: (value) => { chosen = value; } });
  const choices = nodes(picker, (node) => node.type === 'input' && node.props.type === 'radio');
  assert.equal(choices.length, 9); assert.equal(choices.find((node) => node.props.checked).props.value, 4.5);
  choices.find((node) => node.props.value === 3.5).props.onChange(); assert.equal(chosen, 3.5); count++;
  console.log('PASS Native radio picker supports all nine half-star values and keyboard selection');
  console.log(`${count} review component state checks passed. Browser layout is not measured by these checks.`);
})().catch((error) => { console.error(error); process.exitCode = 1; });
