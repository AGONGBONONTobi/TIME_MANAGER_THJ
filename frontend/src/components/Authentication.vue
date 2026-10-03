<script>
import api from '../services/api'
import { writeAuthUser } from '../utils/auth'

export default {
  name: 'AuthForm',
  data() {
    return {
      email: '',
      password: '',
      errorMessage: '',
      isSubmitting: false
    }
  },
  methods: {
    async submit() {
      this.errorMessage = ''

      if (!this.email || !this.password) {
        this.errorMessage = 'Veuillez renseigner votre email et votre mot de passe.'
        return
      }

      this.isSubmitting = true

      try {
        const response = await api.post('/auth/sign_in', {
          email: this.email,
          password: this.password
        })

        const user = (response.data && response.data.user) || response.data || null

        if (!user || !user.id || !user.role) {
          throw new Error('Réponse de connexion incomplète.')
        }

        writeAuthUser({
          id: user.id,
          username: user.username || user.email || 'Utilisateur',
          role: user.role
        })

        this.$router.push('/dashboard')
      } catch (error) {
        const message = error?.response?.data?.error || error?.response?.data?.message || 'Identifiants invalides.'
        this.errorMessage = message
      } finally {
        this.isSubmitting = false
      }
    }
  }
}
</script>

<template>
  <div class="auth-page-shell">
    <div class="auth-panel">
      <div class="auth-copy">
        <p class="auth-kicker">TIME MANAGER</p>
        <h1>Connexion</h1>
        <p>Accédez à votre espace travail et à vos données de pointage.</p>
      </div>

      <form class="auth-form" @submit.prevent="submit">
        <label>
          <span>Email</span>
          <input v-model="email" type="email" placeholder="nombre@entreprise.fr" required />
        </label>

        <label>
          <span>Mot de passe</span>
          <input v-model="password" type="password" placeholder="••••••••" required />
        </label>

        <p v-if="errorMessage" class="form-error" role="alert">{{ errorMessage }}</p>

        <button class="primary-button" type="submit" :disabled="isSubmitting">
          {{ isSubmitting ? 'Connexion…' : 'Se connecter' }}
        </button>

        <p class="auth-switch">
          Pas encore inscrit ?
          <router-link to="/sign_up">Créer un compte</router-link>
        </p>
      </form>
    </div>
  </div>
</template>

<style scoped>
.auth-page-shell {
  display: grid;
  min-height: 100vh;
  place-items: center;
  background: linear-gradient(135deg, #f5f3ff 0%, #eef4ff 100%);
}

.auth-panel {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  width: min(860px, calc(100% - 32px));
  background: #fff;
  border: 1px solid #e8ebf2;
  border-radius: 24px;
  box-shadow: 0 28px 70px rgba(36, 48, 71, 0.12);
  overflow: hidden;
}

.auth-copy {
  padding: 52px 42px;
  background: linear-gradient(180deg, #1f2432 0%, #2a3350 100%);
  color: #fff;
}

.auth-kicker {
  margin: 0 0 16px;
  color: #b7aefc;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.14em;
}

.auth-copy h1 {
  margin: 0 0 16px;
  font-size: clamp(2rem, 3vw, 2.7rem);
}

.auth-copy p {
  margin: 0;
  max-width: 30ch;
  color: rgba(255, 255, 255, 0.75);
  line-height: 1.7;
}

.auth-form {
  display: grid;
  gap: 20px;
  padding: 52px 36px;
}

.auth-form label {
  display: grid;
  gap: 8px;
  color: #3b4453;
  font-weight: 600;
}

.auth-form input {
  width: 100%;
  min-height: 48px;
  padding: 0 14px;
  border: 1px solid #dfe5ee;
  border-radius: 12px;
  background: #fff;
}

.primary-button {
  min-height: 48px;
  border: 0;
  border-radius: 12px;
  background: #7a6ff2;
  color: #fff;
  font-weight: 700;
  cursor: pointer;
}

.primary-button:disabled {
  opacity: 0.7;
  cursor: wait;
}

.form-error {
  margin: 0;
  padding: 10px 12px;
  color: #8a1b1b;
  background: #fdf0f0;
  border: 1px solid #f3c7c7;
  border-radius: 10px;
}

.auth-switch {
  margin: 0;
  color: #576074;
  text-align: center;
}

.auth-switch a {
  color: #675ae9;
  text-decoration: none;
  font-weight: 700;
}

@media (max-width: 720px) {
  .auth-panel {
    grid-template-columns: 1fr;
  }

  .auth-copy,
  .auth-form {
    padding: 32px 22px;
  }
}
</style>
