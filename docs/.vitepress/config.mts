import { defineConfig } from 'vitepress'
import fs from 'fs'
import path from 'path'

// Vite plugin: expose a virtual module that lists public images
function virtualImagesPlugin() {
  const VIRTUAL_ID = 'virtual:images'
  const RESOLVED_VIRTUAL_ID = '\0' + VIRTUAL_ID

  return {
    name: 'virtual-images-list',
    resolveId(id: string) {
      if (id === VIRTUAL_ID) return RESOLVED_VIRTUAL_ID
    },
    load(id: string) {
      if (id !== RESOLVED_VIRTUAL_ID) return
      const publicDir = path.resolve(__dirname, '../public/images')
      let files: string[] = []
      try {
        files = fs
          .readdirSync(publicDir, { withFileTypes: true })
          .filter((d) => d.isFile())
          .map((d) => d.name)
          .filter((name) => /\.(png|jpe?g|gif|webp|avif|svg)$/i.test(name))
          .sort((a, b) => a.localeCompare(b))
      } catch (e) {
        files = []
      }

      // Export absolute public URLs (to be wrapped with withBase at runtime)
      const urls = files.map((f) => `/images/${f}`)
      return `export default ${JSON.stringify(urls)}`
    }
  }
}

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Beauty",
  description: "An improvement in the quality of life",
  // base: '/beauty/',
  vite: {
    plugins: [virtualImagesPlugin()]
  },
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      // { text: 'Home', link: '/' },
      // { text: 'Examples', link: '/markdown-examples' }
    ],

    sidebar: [
      {
        text: 'Examples',
        items: [
          // { text: 'Markdown Examples', link: '/markdown-examples' },
          // { text: 'Runtime API Examples', link: '/api-examples' }
        ]
      }
    ],

    socialLinks: [
      // { icon: 'github', link: 'https://github.com/vuejs/vitepress' }
    ]
  }
})
