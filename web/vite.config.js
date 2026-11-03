import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { fileURLToPath } from 'node:url'

const here = (p) => fileURLToPath(new URL(p, import.meta.url))

// Site multi-página (index + privacidade + termos + suporte) para preservar as
// URLs exigidas pelo app (AppLinks.swift). A saída vai para ../docs, que é a
// pasta publicada pelo GitHub Pages.
export default defineConfig({
  base: '/sub-check/',
  plugins: [react()],
  build: {
    outDir: here('../docs'),
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: here('index.html'),
        privacy: here('privacy.html'),
        terms: here('terms.html'),
        support: here('support.html'),
      },
    },
  },
})
