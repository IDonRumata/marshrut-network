import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://marshrut.eu',
  trailingSlash: 'always',
  build: {
    format: 'directory',
    inlineStylesheets: 'auto',
  },
  prefetch: {
    prefetchAll: false,
    defaultStrategy: 'viewport',
  },
  compressHTML: true,
});
