import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
    vueDevTools(),
    ...(mode === 'mobile' ? [{
      name: 'cordova-runtime-script',
      transformIndexHtml(html) {
        return html
          .replace('<body>', '<body class="is-mobile-app">')
          .replace('</body>', '    <script src="cordova.js"></script>\n  </body>')
      },
    }] : []),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    proxy: {
      '/api': 'http://localhost:4000',
    },
  },
  test: {
      environment: 'jsdom',
      globals: true,
      include: ['test/**/*.spec.js'],
      setupFiles: ['./test/setup.js'],
    },
}))
