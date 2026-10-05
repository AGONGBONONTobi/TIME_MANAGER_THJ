<script>
import api from '../services/api'
import AuthShell from './AuthShell.vue'

export default {
  name: 'UserRegister',
  components: { AuthShell },
  data() {
    return {
      username: '',
      email: '',
      password: '',
      showPassword: false,
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
  <AuthShell
    eyebrow="NOUVEAU COLLABORATEUR"
    title="Votre espace."
    description="Créez votre accès interne pour suivre vos horaires et rejoindre votre espace de travail."
  >
    <form class="auth-form" @submit.prevent="submit">
      <label class="auth-field">
        <span class="auth-field-label">Nom d’utilisateur</span>
        <span class="auth-input-wrap">
          <input v-model="username" class="auth-input" type="text" placeholder="Jean Dupont" autocomplete="name" required />
        </span>
      </label>

      <label class="auth-field">
        <span class="auth-field-label">Adresse email</span>
        <span class="auth-input-wrap">
          <input v-model="email" class="auth-input" type="email" placeholder="vous@entreprise.fr" autocomplete="email" required />
        </span>
      </label>

      <label class="auth-field">
        <span class="auth-field-label">Mot de passe</span>
        <span class="auth-input-wrap">
          <input v-model="password" class="auth-input" :type="showPassword ? 'text' : 'password'" placeholder="Minimum 8 caractères" autocomplete="new-password" required />
          <button class="auth-password-toggle" type="button" :aria-label="showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'" @click="showPassword = !showPassword">
            {{ showPassword ? 'Masquer' : 'Afficher' }}
          </button>
        </span>
      </label>

      <p v-if="errorMessage" class="auth-error" role="alert">{{ errorMessage }}</p>
      <p v-if="successMessage" class="auth-success" role="status">{{ successMessage }}</p>

      <button class="auth-submit" type="submit" :disabled="isSubmitting">
        {{ isSubmitting ? 'Création…' : 'Créer mon compte' }}
      </button>

      <p class="auth-switch">
        Vous avez déjà un accès ?
        <router-link to="/sign_in">Se connecter</router-link>
      </p>
    </form>
  </AuthShell>
</template>
