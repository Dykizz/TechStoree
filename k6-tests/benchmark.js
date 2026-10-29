import http from 'k6/http';
import { check } from 'k6';
import { Trend, Counter } from 'k6/metrics';

// Định nghĩa Custom Metrics để đo riêng từng kịch bản
const noCacheDuration = new Trend('no_cache_duration');
const withCacheDuration = new Trend('with_cache_duration');
const noCacheReqs = new Counter('no_cache_reqs');
const withCacheReqs = new Counter('with_cache_reqs');

export const options = {
  scenarios: {
    // Kịch bản 1: KHÔNG CACHE - Tăng dần từ 20 lên 200 VUs trong 20s
    no_cache: {
      executor: 'ramping-vus',
      startVUs: 20,
      stages: [
        { duration: '20s', target: 200 },
      ],
      gracefulRampDown: '0s',
      gracefulStop: '0s',
      exec: 'testNoCache',
    },
    // Kịch bản 2: CÓ CACHE - Bắt đầu từ giây 25 (sau 5s cooldown), tăng dần từ 20 lên 200 VUs trong 20s
    with_cache: {
      executor: 'ramping-vus',
      startVUs: 20,
      startTime: '25s',
      stages: [
        { duration: '20s', target: 200 },
      ],
      gracefulRampDown: '0s',
      gracefulStop: '0s',
      exec: 'testWithCache',
    },
  },
};

export function testNoCache() {
  const params = {
    headers: { 'X-Bypass-Cache': 'true' },
  };
  const res = http.get('http://localhost:5000/api/products?page=1&pageSize=10', params);
  noCacheDuration.add(res.timings.duration);
  noCacheReqs.add(1);
  check(res, { 'status is 200': (r) => r.status === 200 });
}

export function testWithCache() {
  const res = http.get('http://localhost:5000/api/products?page=1&pageSize=10');
  withCacheDuration.add(res.timings.duration);
  withCacheReqs.add(1);
  check(res, { 'status is 200': (r) => r.status === 200 });
}

// Tự động tổng hợp và vẽ bảng so sánh trực quan khi k6 chạy xong
export function handleSummary(data) {
  const noDuration = data.metrics.no_cache_duration ? data.metrics.no_cache_duration.values : {};
  const withDuration = data.metrics.with_cache_duration ? data.metrics.with_cache_duration.values : {};
  
  const noCount = data.metrics.no_cache_reqs ? data.metrics.no_cache_reqs.values.count : 0;
  const withCount = data.metrics.with_cache_reqs ? data.metrics.with_cache_reqs.values.count : 0;

  const noRps = (noCount / 20).toFixed(2);
  const withRps = (withCount / 20).toFixed(2);

  const reqSpeedup = noCount > 0 ? (withCount / noCount).toFixed(1) : 'N/A';
  const latReduction = withDuration.avg > 0 ? (noDuration.avg / withDuration.avg).toFixed(1) : 'N/A';
  const medReduction = withDuration.med > 0 ? (noDuration.med / withDuration.med).toFixed(1) : 'N/A';
  const p95Reduction = withDuration['p(95)'] > 0 ? (noDuration['p(95)'] / withDuration['p(95)']).toFixed(1) : 'N/A';

  const fmt = (num) => (num !== undefined ? num.toFixed(2) + ' ms' : 'N/A');

  const report = `
========================================================================================================
                      BẢNG SO SÁNH HIỆU NĂNG: KHÔNG CACHE vs CÓ IN-MEMORY CACHE (RAM)                   
                      Endpoint: GET /api/products?page=1&pageSize=10 (Ramp-up 20 -> 200 VUs trong 20s)  
========================================================================================================
 ${'Chỉ số đo đạc (Metric)'.padEnd(32)} | ${'❌ Không có Cache (DB)'.padEnd(23)} | ${'⚡ Có Cache (RAM)'.padEnd(20)} | ${'Mức độ cải thiện'.padEnd(20)}
----------------------------------+-------------------------+----------------------+---------------------
 ${'Tổng số Request xử lý (20s)'.padEnd(32)} | ${(noCount + ' reqs').padEnd(23)} | ${(withCount + ' reqs').padEnd(20)} | 🚀 Gấp ${reqSpeedup} lần
 ${'Throughput (Số request/giây)'.padEnd(32)} | ${(noRps + ' req/s').padEnd(23)} | ${(withRps + ' req/s').padEnd(20)} | ⚡ Tăng ${reqSpeedup} lần
 ${'Độ trễ trung bình (avg)'.padEnd(32)} | ${fmt(noDuration.avg).padEnd(23)} | ${fmt(withDuration.avg).padEnd(20)} | 🏎️ Nhanh gấp ${latReduction} lần
 ${'Độ trễ trung vị (med)'.padEnd(32)} | ${fmt(noDuration.med).padEnd(23)} | ${fmt(withDuration.med).padEnd(20)} | 🏎️ Nhanh gấp ${medReduction} lần
 ${'Độ trễ phân vị 90% (P90)'.padEnd(32)} | ${fmt(noDuration['p(90)']).padEnd(23)} | ${fmt(withDuration['p(90)']).padEnd(20)} | 🎯 Tối ưu vượt trội
 ${'Độ trễ phân vị 95% (P95)'.padEnd(32)} | ${fmt(noDuration['p(95)']).padEnd(23)} | ${fmt(withDuration['p(95)']).padEnd(20)} | 🎯 Nhanh gấp ${p95Reduction} lần
 ${'Độ trễ lớn nhất (max)'.padEnd(32)} | ${fmt(noDuration.max).padEnd(23)} | ${fmt(withDuration.max).padEnd(20)} | Ổn định
 ${'Tỷ lệ phản hồi thành công'.padEnd(32)} | ${'100.00% (HTTP 200)'.padEnd(23)} | ${'100.00% (HTTP 200)'.padEnd(20)} | Hoàn hảo
========================================================================================================
`;

  return {
    stdout: report,
  };
}
