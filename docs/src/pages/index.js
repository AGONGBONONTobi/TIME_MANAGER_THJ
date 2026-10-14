import Link from '@docusaurus/Link'
import Layout from '@theme/Layout'
import Heading from '@theme/Heading'

const areas = [
  { title: 'Backend Phoenix', description: 'Contextes Elixir, schémas Ecto, contrôleurs et routes HTTP.', link: '/docs/backend/domains' },
  { title: 'Frontend Vue', description: 'Composants, navigation, appels API et synchronisation.', link: '/docs/frontend/components' },
  { title: 'Données & API', description: 'Modèles persistés, formats d’échange et endpoints déclarés.', link: '/docs/data-model' },
  { title: 'Mobile & sécurité', description: 'Cordova, mode hors-ligne, authentification et limites connues.', link: '/docs/mobile' },
]

export default function Home() {
  return (
    <Layout title="Documentation du code" description="Documentation technique du projet Time Manager">
      <main className="container margin-vert--xl">
        <header className="text--center margin-bottom--xl">
          <Heading as="h1">Time Manager</Heading>
          <p className="hero__subtitle">Comprendre le code, les flux de données et les responsabilités de chaque couche.</p>
          <Link className="button button--primary button--lg" to="/docs">Explorer la documentation</Link>
        </header>
        <section className="row">
          {areas.map((area) => (
            <article className="col col--6 margin-bottom--lg" key={area.title}>
              <div className="card">
                <div className="card__header"><Heading as="h2">{area.title}</Heading></div>
                <div className="card__body"><p>{area.description}</p></div>
                <div className="card__footer">
                  <Link className="button button--secondary button--block" to={area.link}>Lire cette section</Link>
                </div>
              </div>
            </article>
          ))}
        </section>
      </main>
    </Layout>
  )
}