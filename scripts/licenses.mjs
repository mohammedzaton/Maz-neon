import { readFile, readdir, writeFile } from 'node:fs/promises';
const names=['three','cannon-es','nipplejs','@capacitor/core','@capacitor/android','@capacitor/app','@capacitor-community/admob'];
let notices='MAZ Neon Rush — bundled dependency notices\n\n';
for(const name of names){const base='node_modules/'+name;const pkg=JSON.parse(await readFile(base+'/package.json','utf8'));const entries=await readdir(base);const file=entries.find(n=>/^licen[cs]e(?:\.md|\.txt)?$/i.test(n));if(!file)throw new Error('Missing license: '+name);notices+=`\n=== ${name} ${pkg.version} (${pkg.license}) ===\n`+await readFile(base+'/'+file,'utf8')+'\n';}
await writeFile('public/THIRD_PARTY_LICENSES.txt',notices);
console.log('Saved license notices for '+names.length+' direct runtime dependencies');
