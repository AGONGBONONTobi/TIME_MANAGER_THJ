<script>
import api from '../services/api'
import { readAuthUser, writeAuthUser } from '../utils/auth'

export default {
  name: 'ChangePassword',
  data() {
    return {
      currentPassword: '',
      newPassword: '',
      confirmation: '',
      errorMessage: '',
      isSubmitting: false
    }
  },
  methods: {
    async submit() {
      this.errorMessage = ''
      if (this.newPassword.length < 12) {
        this.errorMessage = 'Choisissez un mot de passe d’au moins 12 caractères.'
        return
      }
      if (this.newPassword !== this.confirmation) {
        this.errorMessage = 'Les nouveaux mots de passe ne correspondent pas.'
        return
      }

      this.isSubmitting = true
      try {
        const response = await api.changePassword({
          current_password: this.currentPassword,
          new_password: this.newPassword
        })
        writeAuthUser(response.data?.user || {
          ...readAuthUser(),
          must_change_password: false
        })
        await this.$router.replace('/dashboard')
      } catch (error) {
        this.errorMessage = error.response?.data?.error || 'Le mot de passe n’a pas pu être modifié.'
      } finally {
        this.isSubmitting = false
      }
    }
  }
}
</script>

<template>
  <main class="password-page">
    <section class="password-card">
      <p class="eyebrow">SÉCURITÉ DU COMPTE</p>
      <h1>Choisissez votre mot de passe personnel</h1>
      <p>Votre administrateur vous a fourni un mot de passe temporaire. Remplacez-le pour continuer.</p>
      <form @submit.prevent="submit">
        <label>
          Mot de passe temporaire
          <input v-model="currentPassword" type="password" autocomplete="current-password" required>
        </label>
        <label>
          Nouveau mot de passe (12 caractères minimum)
          <input v-model="newPassword" type="password" autocomplete="new-password" minlength="12" required>
        </label>
        <label>
          Confirmer le nouveau mot de passe
          <input v-model="confirmation" type="password" autocomplete="new-password" minlength="12" required>
        </label>
        <p v-if="errorMessage" class="error-message" role="alert">{{ errorMessage }}</p>
        <button type="submit" :disabled="isSubmitting">
          {{ isSubmitting ? 'Enregistrement…' : 'Enregistrer et continuer' }}
        </button>
      </form>
    </section>
  </main>
</template>

<style scoped>
.password-page { display: grid; min-height: 70vh; place-items: center; padding: 24px; }
.password-card { width: min(100%, 520px); padding: 32px; background: #fff; border: 1px solid #e6eaf0; border-radius: 16px; box-shadow: 0 16px 42px #1e2c4210; }
.eyebrow { margin: 0 0 12px; color: #786be7; font-size: 11px; font-weight: 800; letter-spacing: .13em; }
h1 { margin: 0; font-size: clamp(1.7rem, 5vw, 2.2rem); }
.password-card > p:not(.eyebrow) { color: #677181; line-height: 1.6; }
form { display: grid; gap: 16px; margin-top: 24px; }
label { display: grid; gap: 7px; color: #3d4654; font-size: 13px; font-weight: 700; }
input { min-height: 44px; padding: 10px 12px; border: 1px solid #ccd3dd; border-radius: 7px; font: inherit; }
button { min-height: 46px; color: #fff; background: #786be7; border: 0; border-radius: 7px; font-weight: 800; cursor: pointer; }
button:disabled { cursor: wait; opacity: .65; }
.error-message { margin: 0; color: #b6444d; }
</style>
