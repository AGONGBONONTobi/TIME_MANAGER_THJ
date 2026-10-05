<script>
export default {
  name: 'AccessDenied'
}
</script>

<template>
  <div class="unauthorized-shell">
    <div class="unauthorized-card">
      <p class="eyebrow">ACCÈS REFUSÉ</p>
      <h1>Vous n’avez pas les droits nécessaires pour voir cette page.</h1>
      <router-link to="/dashboard">Retour au tableau de bord</router-link>
    </div>
  </div>
</template>

<style scoped>
.unauthorized-shell {
  display: grid;
  min-height: calc(100vh - 72px);
  place-items: center;
  padding: 32px;
}

.unauthorized-card {
  width: min(560px, 100%);
  padding: 40px 32px;
  text-align: center;
  background: #fff;
  border: 1px solid #eceff5;
  border-radius: 20px;
  box-shadow: 0 24px 60px rgba(32, 38, 49, 0.08);
}

.eyebrow {
  margin: 0 0 16px;
  color: #8f5a5a;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.14em;
}

h1 {
  margin: 0 0 22px;
  line-height: 1.4;
}

router-link,
a {
  color: #685ce7;
  font-weight: 700;
  text-decoration: none;
}
</style>
