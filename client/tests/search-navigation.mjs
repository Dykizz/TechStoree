// React element identity and event/state regression checks; no browser automation.
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const ts = require('typescript');
const jsx = require('react/jsx-runtime');

function find(tree, type) {
  if (!tree || typeof tree !== 'object') return undefined;
  if (tree.type === type) return tree;
  for (const child of [tree.props?.children].flat(Infinity)) {
    const result = find(child, type);
    if (result) return result;
  }
}

function harness(file, initialQuery = '') {
  let query = new URLSearchParams(initialQuery);
  let cursor = 0;
  const slots = [], effects = [], navigations = [];
  const hooks = {
    Suspense: 'Suspense',
    useState(initial) {
      const index = cursor++;
      if (!(index in slots)) slots[index] = typeof initial === 'function' ? initial() : initial;
      return [slots[index], (value) => { slots[index] = typeof value === 'function' ? value(slots[index]) : value; }];
    },
    useRef(initial) {
      const index = cursor++;
      if (!(index in slots)) slots[index] = { current: initial };
      return slots[index];
    },
    useMemo: (fn) => fn(), useCallback: (fn) => fn,
    useEffect(fn) { effects.push(fn); },
  };
  const moduleShim = { exports: {} };
  const compiled = ts.transpileModule(fs.readFileSync(new URL(file, import.meta.url), 'utf8'), {
    compilerOptions: { jsx: ts.JsxEmit.ReactJSX, target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.CommonJS },
  }).outputText;
  vm.runInNewContext(compiled, {
    module: moduleShim, exports: moduleShim.exports, URLSearchParams,
    window: { history: { replaceState(_state, _title, url) { query = new URL(url, 'http://localhost').searchParams; } } },
    require(name) {
      if (name === 'react') return hooks;
      if (name === 'react/jsx-runtime') return jsx;
      if (name === 'next/navigation') return { useSearchParams: () => query, useRouter: () => ({ push: (url) => navigations.push(url) }) };
      if (name.endsWith('/useCategories')) return { useCategories: () => ({ data: [] }) };
      if (name.endsWith('/useProducts')) return { useProducts: () => ({ data: { items: [] } }) };
      if (name.endsWith('/utils')) return { cn: (...values) => values.filter(Boolean).join(' ') };
      if (name.endsWith('/products-client')) return { formatPrice: String };
      if (name.endsWith('/search-engine')) return {};
      return { default: name.split('/').at(-1) };
    },
  });
  function boundary() {
    let tree = moduleShim.exports.default();
    if (tree.type === 'Suspense') tree = tree.props.children;
    while (typeof tree.type === 'function' && tree.type.name !== 'ProductsContent') tree = tree.type(tree.props);
    return tree;
  }
  return {
    boundary, navigations, query: () => query,
    navigate(value) { query = new URLSearchParams(value); },
    render() {
      cursor = 0; effects.length = 0;
      if (file.includes('/products/')) { const node = boundary(); return node.type(node.props); }
      return moduleShim.exports.default();
    },
    syncExternalUrl() { effects[0]?.(); },
  };
}

const catalog = harness('../app/products/page.tsx', 'minPrice=100&maxPrice=500');
const original = catalog.boundary();
let tree = catalog.render();
catalog.syncExternalUrl();
for (const value of ['i', 'ip', 'iphone ', 'iphone pro']) {
  find(tree, 'SearchBar').props.onChange(value);
  const next = catalog.boundary();
  assert.equal(next.type, original.type);
  assert.equal(next.key, original.key, 'Typing must not replace the catalog subtree and its focused input');
  tree = catalog.render();
  catalog.syncExternalUrl();
  tree = catalog.render();
  assert.equal(find(tree, 'SearchBar').props.value, value, 'Local text, including a trailing space, must survive URL synchronization');
  assert.equal(catalog.query().get('minPrice'), '100');
  assert.equal(catalog.query().get('maxPrice'), '500');
}
console.log('PASS Typing preserves the React input subtree, draft spaces and active price filters');

catalog.navigate('search=sony&category=2&page=2');
catalog.render(); catalog.syncExternalUrl(); tree = catalog.render();
assert.equal(find(tree, 'SearchBar').props.value, 'sony');
assert.equal(catalog.query().get('category'), '2');
console.log('PASS External URL navigation restores the search text');

const home = harness('../components/search/HomeSearch.tsx');
tree = home.render();
find(tree, 'SearchBar').props.onChange('điện thoại & phụ kiện');
tree = home.render();
find(tree, 'form').props.onSubmit({ preventDefault() {} });
const destination = new URL(home.navigations[0], 'http://localhost');
assert.equal(destination.pathname, '/products');
assert.equal(destination.searchParams.get('search'), 'điện thoại & phụ kiện');
find(tree, 'SearchBar').props.onSearch('MacBook');
assert.equal(new URL(home.navigations[1], 'http://localhost').searchParams.get('search'), 'MacBook');
find(tree, 'SearchBar').props.onSearch('');
assert.equal(home.navigations.length, 2, 'Clearing the home input must not navigate');
console.log('PASS Home submit and suggestions navigate with encoded keywords; clearing stays on home');
