/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Time Manager — Documentation du code',
  tagline: 'Architecture, modules, API et fonctionnement du projet',
  url: 'http://localhost:8000',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  markdown: { hooks: { onBrokenMarkdownLinks: 'warn' } },
  i18n: { defaultLocale: 'fr', locales: ['fr'] },
  presets: [
    [
      'classic',
      {
        docs: { sidebarPath: './sidebars.js', routeBasePath: 'docs' },
        blog: false,
      },
    ],
  ],
  themeConfig: {
    navbar: {
      title: 'Time Manager',
      items: [
        { type: 'docSidebar', sidebarId: 'tutorialSidebar', position: 'left', label: 'Documentation du code' },
      ],
    },
    footer: {
      links: [
        {
          title: 'Projet',
          items: [
            { label: 'Démarrage', to: '/docs/getting-started' },
            { label: 'Architecture', to: '/docs/architecture' },
            { label: 'API', to: '/docs/backend/api' },
          ],
        },
      ],
      copyright: `Time Manager · ${new Date().getFullYear()}`,
    },
  },
}

export default config