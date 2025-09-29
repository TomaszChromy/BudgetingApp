const CACHE = 'budgetingapp-v8';
const ASSETS = [
  './','./index.html','./manifest.webmanifest',
  './assets/icon-192.png','./assets/icon-512.png',
  'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js'
];
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(()=>self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(()=> self.clients.claim()));
});
self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(hit => hit || fetch(e.request).then(res => {
      try {
        const copy = res.clone();
        const sameOrigin = new URL(e.request.url).origin === location.origin;
        if (e.request.method === 'GET' && res.ok && (sameOrigin || e.request.url.includes('cdn.jsdelivr.net'))) {
          caches.open(CACHE).then(c => c.put(e.request, copy));
        }
      } catch (_) {}
      return res;
    }).catch(() => {
      if (e.request.mode === 'navigate') return caches.match('./index.html');
    }))
  );
});


