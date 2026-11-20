#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-unpacked/outpost_v08}"
test -f "$ROOT/index.html"
test -f "$ROOT/sw.js"

cat > "$ROOT/sw.js" <<'SW'
const CACHE = 'outpost-shell-v08';
const BASE = new URL('.', self.location).pathname;
const ASSETS = [
  BASE,
  BASE + 'index.html',
  BASE + 'manifest.webmanifest',
  BASE + 'supabase-config.js',
  BASE + 'icon.svg',
  BASE + 'icon-192.png',
  BASE + 'icon-512.png',
  BASE + 'wallpaper-preview.html',
  BASE + 'outpost-wallpaper-engine.zip'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys
          .filter(key => key.startsWith('outpost-shell-') && key !== CACHE)
          .map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return;

  event.respondWith(
    caches.match(request).then(async cached => {
      if (cached) return cached;
      try {
        const response = await fetch(request);
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE).then(cache => cache.put(request, copy));
        }
        return response;
      } catch {
        if (request.mode === 'navigate') {
          const fallback = await caches.match(BASE + 'index.html');
          if (fallback) return fallback;
        }
        return Response.error();
      }
    })
  );
});
SW

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])

# Keep version labels consistent with the archive actually being deployed.
for name in ("SUPABASE-SETUP.md", "schema.sql", "supabase-config.js", "index.html"):
    path = root / name
    text = path.read_text(encoding="utf-8")
    text = text.replace("OUTPOST 0.7", "OUTPOST 0.8")
    text = text.replace("OUTPOST 0.6 cloud backend", "OUTPOST 0.8 cloud backend")
    text = text.replace("OUTPOST 0.6", "OUTPOST 0.8")
    text = text.replace("## Что уже реализовано в 0.6", "## Что уже реализовано в 0.8")
    path.write_text(text, encoding="utf-8")

# Avoid making Supabase requests from inside its auth-state callback; the client
# may still hold its internal auth lock while notifying listeners.
path = root / "index.html"
text = path.read_text(encoding="utf-8")
old = "if(cloudUser)loadCloudGallery();else{$('#cloudGalleryGrid').innerHTML='';cloudStatus"
new = "if(cloudUser)setTimeout(()=>loadCloudGallery(),0);else{$('#cloudGalleryGrid').innerHTML='';cloudStatus"
count = text.count(old)
if count != 1:
    raise SystemExit(f"Expected exactly one auth callback to patch, found {count}")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
print("Applied OUTPOST 0.8 compatibility, cache-scope, and auth-callback fixes.")
PY
