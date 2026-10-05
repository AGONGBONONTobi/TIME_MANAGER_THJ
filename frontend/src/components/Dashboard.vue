<script>
import { readAuthUser } from '../utils/auth'

export default {
  name: 'UserDashboard',
  computed: {
    currentUser() {
      return readAuthUser()
    }
  },
  mounted() {
    if (!this.currentUser) {
      this.$router.replace('/sign_in')
      return
    }

    const role = String(this.currentUser.role).toLowerCase()
    if (role === 'admin') {
      this.$router.replace('/admin')
    } else if (role === 'manager') {
      this.$router.replace('/manager')
    } else {
      this.$router.replace('/employee')
    }
  }
}
</script>

<template>
  <section class="page-panel" v-if="currentUser">
    <div class="page-header">
      <div>
        <p class="eyebrow">TABLEAU DE BORD</p>
        <h1>Bienvenue {{ currentUser.username || 'utilisateur' }}</h1>
      </div>
    </div>

    <div class="info-grid">
      <div class="info-card">
        <span>Identifiant</span>
        <strong>{{ currentUser.id }}</strong>
      </div>
      <div class="info-card">
        <span>Nom</span>
        <strong>{{ currentUser.username || 'Utilisateur' }}</strong>
      </div>
      <div class="info-card">
        <span>Rôle</span>
        <strong>{{ currentUser.role }}</strong>
      </div>
    </div>
  </section>
</template>

<style scoped>
.page-panel {
  display: grid;
  gap: 24px;
  padding: 32px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: end;
}

.eyebrow {
  margin: 0 0 8px;
  color: #7667ef;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.12em;
}

h1 {
  margin: 0;
  font-size: clamp(2rem, 2.8vw, 2.7rem);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 18px;
}

.info-card {
  display: grid;
  gap: 8px;
  padding: 20px;
  background: #fff;
  border: 1px solid #e6ebf3;
  border-radius: 16px;
  box-shadow: 0 16px 40px rgba(35, 47, 67, 0.04);
}

.info-card span {
  color: #697586;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.info-card strong {
  font-size: 1.4rem;
}
</style>
