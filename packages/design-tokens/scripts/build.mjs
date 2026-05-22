import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');
const srcPath = resolve(root, 'src/tokens.json');
const distDir = resolve(root, 'dist');

const tokens = JSON.parse(await readFile(srcPath, 'utf8'));

const cssLines = [
  '/* Generated from src/tokens.json — do not edit by hand */',
  '/* Source: @marshrut/design-tokens */',
  '',
  ':root {',
];

function emit(category, prefix) {
  const section = tokens[category];
  if (!section) return;
  cssLines.push(`  /* ${category} */`);
  for (const [name, entry] of Object.entries(section)) {
    if (entry && typeof entry === 'object' && 'value' in entry) {
      cssLines.push(`  --${prefix}-${name}: ${entry.value};`);
    } else if (entry && typeof entry === 'object') {
      for (const [sub, subEntry] of Object.entries(entry)) {
        if (subEntry && typeof subEntry === 'object' && 'value' in subEntry) {
          cssLines.push(`  --${prefix}-${name}-${sub}: ${subEntry.value};`);
        }
      }
    }
  }
  cssLines.push('');
}

emit('color', 'color');
emit('font', 'font');
emit('space', 'space');
emit('radius', 'radius');
emit('shadow', 'shadow');
emit('breakpoint', 'bp');
emit('content', 'content');

cssLines.push('}');

await mkdir(distDir, { recursive: true });
await writeFile(resolve(distDir, 'tokens.css'), cssLines.join('\n'), 'utf8');
await writeFile(resolve(distDir, 'tokens.json'), JSON.stringify(tokens, null, 2), 'utf8');

console.log(`Built ${cssLines.length} lines of CSS to dist/tokens.css`);
console.log(`Copied JSON to dist/tokens.json`);
