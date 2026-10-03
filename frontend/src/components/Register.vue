<script>
import api from '../services/api'

export default {
  name: 'UserRegister',
  data() {
    return {
      username: '',
      email: '',
      password: '',
      errorMessage: '',
      isSubmitting: false,
      successMessage: ''
    }
  },
  methods: {
    async submit() {
      this.errorMessage = ''
      this.successMessage = ''

      if (!this.username || !this.email || !this.password) {
        this.errorMessage = 'Tous les champs sont obligatoires.'
        return
      }

      if (this.password.length < 8) {
        this.errorMessage = 'Le mot de passe doit contenir au moins 8 caractères.'
        return
      }

      this.isSubmitting = true

      try {
        await api.post('/auth/sign_up', {
          username: this.username,
          email: this.email,
          password: this.password
        })

        this.successMessage = 'Compte créé avec succès. Redirection vers la connexion…'
        this.username = ''
        this.email = ''
        this.password = ''

        setTimeout(() => {
          this.$router.push('/sign_in')
        }, 600)
      } catch (error) {
        const message = error?.response?.data?.error || error?.response?.data?.message || 'Impossible de créer le compte.'
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
        <p class="auth-kicker">CRÉER UN COMPTE</p>
        <h1>Inscription</h1>
        <p>Créez votre accès pour gérer vos temps de travail et votre agenda.</p>
      </div>

      <form class="auth-form" @submit.prevent="submit">
        <label>
          <span>Nom d’utilisateur</span>
          <input v-model="username" type="text" placeholder="Jean Dupont" required />
        </label>

        <label>
          <span>Email</span>
          <input v-model="email" type="email" placeholder="jean@entreprise.fr" required />
        </label>

        <label>
          <span>Mot de passe</span>
          <input v-model="password" type="password" placeholder="Minimum 8 caractères" required />
        </label>

        <p v-if="errorMessage" class="form-error" role="alert">{{ errorMessage }}</p>
        <p v-if="successMessage" class="form-success" role="status">{{ successMessage }}</p>

        <button class="primary-button" type="submit" :disabled="isSubmitting">
          {{ isSubmitting ? 'Création…' : 'Créer mon compte' }}
        </button>

        <p class="auth-switch">
          Déjà inscrit ?
          <router-link to="/sign_in">Se connecter</router-link>
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
  background: linear-gradient(135deg, #eef6ff 0%, #f6f4ff 100%);
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
  background: linear-gradient(180deg, #1c2a3b 0%, #394862 100%);
  color: #fff;
}

.auth-kicker {
  margin: 0 0 16px;
  color: #c5d2ff;
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
  color: rgba(255, 255, 255, 0.76);
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
  background: #4f7ef7;
  color: #fff;
  font-weight: 700;
  cursor: pointer;
}

.primary-button:disabled {
  opacity: 0.7;
  cursor: wait;
}

.form-error,
.form-success {
  margin: 0;
  padding: 10px 12px;
  border-radius: 10px;
}

.form-error {
  color: #8a1b1b;
  background: #fdf0f0;
  border: 1px solid #f3c7c7;
}

.form-success {
  color: #216b3f;
  background: #edfdf2;
  border: 1px solid #b8e6c3;
}

.auth-switch {
  margin: 0;
  color: #576074;
  text-align: center;
}

.auth-switch a {
  color: #2d6fed;
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
