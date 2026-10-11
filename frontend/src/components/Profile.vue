<script>
import api from '../services/api'
import { readAuthUser, writeAuthUser } from '../utils/auth'

export default {
  name: 'ProfilePage',
  data: () => ({ user: readAuthUser(), currentPassword: '', newPassword: '', confirmation: '', message: '', error: '', loading: false }),
  async mounted() {
    try { this.user = (await api.getCurrentUser()).data?.user || this.user } catch { this.error = 'Impossible de charger le profil.' }
  },
  methods: {
    async changePassword() {
      this.message = ''; this.error = ''
      if (this.newPassword.length < 8 || this.newPassword !== this.confirmation) { this.error = 'Le nouveau mot de passe doit contenir 8 caractères et les confirmations doivent correspondre.'; return }
      this.loading = true
      try { await api.changePassword({ current_password: this.currentPassword, new_password: this.newPassword }); this.message = 'Mot de passe modifié avec succès.'; this.currentPassword = ''; this.newPassword = ''; this.confirmation = '' } catch (error) { this.error = error.response?.data?.error || 'Le mot de passe n’a pas pu être modifié.' } finally { this.loading = false }
    },
    async saveProfile() {
      try { const response = await api.updateUser(this.user.id, { username: this.user.username, email: this.user.email }); this.user = response.data?.data || this.user; writeAuthUser(this.user); this.message = 'Profil mis à jour.' } catch { this.error = 'Le profil n’a pas pu être mis à jour.' }
    }
  }
}
</script>

<template>
  <section class="profile-page"><p class="eyebrow">MON COMPTE</p><h1>Profil</h1>
    <form class="profile-card" @submit.prevent="saveProfile"><label>Nom d’utilisateur<input v-model="user.username" required></label><label>Email<input v-model="user.email" type="email" required></label><p>Rôle : <strong>{{ user.role }}</strong></p><button type="submit">Enregistrer le profil</button></form>
    <form class="profile-card" @submit.prevent="changePassword"><h2>Changer le mot de passe</h2><label>Ancien mot de passe<input v-model="currentPassword" type="password" required></label><label>Nouveau mot de passe<input v-model="newPassword" type="password" minlength="8" required></label><label>Confirmation<input v-model="confirmation" type="password" required></label><button type="submit" :disabled="loading">Modifier le mot de passe</button></form>
    <p v-if="message" class="success">{{ message }}</p><p v-if="error" class="error">{{ error }}</p>
  </section>
</template>

<style scoped>
.profile-page { max-width: 720px; margin: auto; }.profile-card { display: grid; gap: 12px; margin: 18px 0; padding: 20px; background: #fff; border-radius: 10px; }.profile-card label { display: grid; gap: 5px; font-weight: 700; }.profile-card input { padding: 10px; border: 1px solid #ddd; border-radius: 6px; }.profile-card button { width: fit-content; padding: 10px 14px; color: #fff; background: #786be7; border: 0; border-radius: 6px; }.success { color: #287a4d; }.error { color: #b6444d; }
</style>
