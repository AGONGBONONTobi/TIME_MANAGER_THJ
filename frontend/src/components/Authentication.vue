<script>
import api from '../services/api'
import { writeAuthToken, writeAuthUser } from '../utils/auth'
import AuthShell from './AuthShell.vue'

export default {
  name: 'AuthForm',
  components: { AuthShell },
  data() {
    return {
      email: '',
      password: '',
      showPassword: false,
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

        writeAuthToken(response.data?.token)
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
  <AuthShell
    eyebrow="ESPACE COLLABORATEUR"
    title="Bienvenue."
    description="Connectez-vous pour retrouver votre espace de travail et le suivi de vos horaires."
  >
    <form class="auth-form" @submit.prevent="submit">
      <label class="auth-field">
        <span class="auth-field-label">Adresse email</span>
        <span class="auth-input-wrap">
          <input v-model="email" class="auth-input" type="email" placeholder="vous@entreprise.fr" autocomplete="email" required />
        </span>
      </label>

      <label class="auth-field">
        <span class="auth-field-label">Mot de passe</span>
        <span class="auth-input-wrap">
          <input v-model="password" class="auth-input" :type="showPassword ? 'text' : 'password'" placeholder="Votre mot de passe" autocomplete="current-password" required />
          <button class="auth-password-toggle" type="button" :aria-label="showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'" @click="showPassword = !showPassword">
            {{ showPassword ? 'Masquer' : 'Afficher' }}
          </button>
        </span>
      </label>

      <p v-if="errorMessage" class="auth-error" role="alert">{{ errorMessage }}</p>

      <button class="auth-submit" type="submit" :disabled="isSubmitting">
        {{ isSubmitting ? 'Connexion…' : 'Se connecter' }}
      </button>

      <p class="auth-switch">
        Première connexion ?
        <router-link to="/sign_up">Créer un compte</router-link>
      </p>
    </form>
  </AuthShell>
</template>
