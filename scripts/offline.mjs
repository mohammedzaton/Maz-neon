import { readdir, writeFile, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
const assets = await readdir('dist/assets');
const version=createHash('sha256').update(await readFile('dist/index.html')).digest('hex').slice(0,12);
const paths=['./','./index.html','./privacy.html','./icon.svg','./THIRD_PARTY_LICENSES.txt',...assets.map(a=>'./assets/'+a)];
await writeFile('dist/sw.js',`const CACHE='maz-neon-${version}';const FILES=${JSON.stringify(paths)};self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES)));self.skipWaiting()});self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('maz-neon-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));self.addEventListener('fetch',e=>{if(e.request.method==='GET'&&new URL(e.request.url).origin===self.location.origin)e.respondWith(caches.match(e.request).then(hit=>hit||fetch(e.request)))});`);
// Registration stays web-only. Android bundles all web assets locally.
let html=await readFile('dist/index.html','utf8');
html=html.replace('</body>',`<script>if('serviceWorker' in navigator && location.protocol==='https:' && !window.Capacitor?.isNativePlatform?.())navigator.serviceWorker.register('./sw.js').catch(()=>{});</script></body>`);
await writeFile('dist/index.html',html);
