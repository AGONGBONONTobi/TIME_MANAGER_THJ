<template>
  <section class="hero-section">
    <div class="hero-content">
      <p class="hero-eyebrow">Gotham · Time Manager</p>
      <h1 class="hero-title">
        <img src="@/assets/logo.jpg" alt="Time Manager Logo" class="brand-logo" />
        Time Manager
      </h1>
      <p class="hero-lead">
        À Gotham, chaque heure compte. Un travail rigoureux pour une ville qui ne dort jamais.
      </p>
      <hr />
      <p class="hero-footer">
        Gérez vos équipes et visualisez les données en un clin d'œil.
      </p>
    </div>
  </section>
</template>

<style scoped>
.hero-section {
  position: relative;
  min-height: 360px;
  display: grid;
  place-items: center;
  overflow: hidden;
  padding: 3rem 1.5rem;
  color: #fff;
  text-align: center;
  background: linear-gradient(rgba(0, 0, 0, 0.7), rgba(0, 0, 0, 0.7)),
    url('../assets/gotham.jpg') center / cover;
  border-radius: 1.5rem;
  box-shadow: 0 20px 45px rgba(37, 33, 27, 0.18);
}

.hero-content {
  max-width: 700px;
}

.hero-eyebrow {
  margin-bottom: 1rem;
  color: #fff;
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.18em;
  text-transform: uppercase;
}

h1.hero-title {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 18px;
  margin-bottom: 1rem;
  font-size: clamp(2.5rem, 7vw, 5rem);
  font-weight: 800;
  letter-spacing: -0.05em;
}

.hero-title .brand-logo {
  width: clamp(28px, 4.5vw, 40px);
  height: clamp(28px, 4.5vw, 40px);
  border-radius: 50%;
  object-fit: cover;
  border: 1.5px solid #fff;
}

.hero-lead {
  margin: 0 auto;
  font-size: clamp(1.05rem, 2vw, 1.3rem);
  line-height: 1.6;
}

hr {
  width: 70px;
  margin: 1.75rem auto;
  border: 0;
  border-top: 2px solid #fff;
  opacity: 1;
}

.hero-footer {
  margin-bottom: 0;
  color: rgba(255, 255, 255, 0.82);
}

@media (max-width: 576px) {
  .hero-section {
    min-height: 420px;
    padding: 2rem 1.25rem;
    border-radius: 1rem;
  }
}
</style>
