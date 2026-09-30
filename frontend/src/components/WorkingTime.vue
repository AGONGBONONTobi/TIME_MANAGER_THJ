<script>
import api from '../services/api'

const emptyWorkingTime = () => ({ start: '', end: '' })

export default {
  name: 'WorkingTime',
  props: {
    userID: { type: [String, Number], required: true },
    workingTimeID: { type: [String, Number], default: null }
  },
  data() {
    return {
      form: emptyWorkingTime(),
      isLoading: false,
      isSaving: false,
      errorMessage: ''
    }
  },
  computed: {
    isEditing() { return Boolean(this.workingTimeID) },
    title() { return this.isEditing ? 'Modifier une session' : 'Créer une session' }
  },
  async mounted() {
    if (this.isEditing) await this.loadWorkingTime()
  },
  methods: {
    toInputDateTime(value) {
      if (!value) return ''
      const date = new Date(value)
      const pad = (part) => String(part).padStart(2, '0')
      return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
    },
    toApiDateTime(value) {
      if (!value) return null
      return new Date(value).toISOString().replace('.000Z', 'Z')
    },
    async loadWorkingTime() {
      this.isLoading = true
      this.errorMessage = ''
      try {
        const response = await api.getWorkingTime(this.userID, this.workingTimeID)
        const workingTime = response.data.data
        this.form = {
          start: this.toInputDateTime(workingTime.start),
          end: this.toInputDateTime(workingTime.end)
        }
      } catch {
        this.errorMessage = 'Impossible de charger cette session.'
      } finally {
        this.isLoading = false
      }
    },
    payload() {
      return {
        start: this.toApiDateTime(this.form.start),
        ...(this.form.end ? { end: this.toApiDateTime(this.form.end) } : {})
      }
    },
    async createWorkingTime() {
      this.isSaving = true
      this.errorMessage = ''
      try {
        await api.createWorkingTime(this.userID, this.payload())
        await this.$router.push({ name: 'workingTimes', params: { userID: this.userID } })
      } catch {
        this.errorMessage = 'Impossible de créer cette session. Vérifiez les dates saisies.'
      } finally {
        this.isSaving = false
      }
    },
    async updateWorkingTime() {
      this.isSaving = true
      this.errorMessage = ''
      try {
        await api.updateWorkingTime(this.workingTimeID, this.payload())
        await this.$router.push({ name: 'workingTimes', params: { userID: this.userID } })
      } catch {
        this.errorMessage = 'Impossible de modifier cette session. Vérifiez les dates saisies.'
      } finally {
        this.isSaving = false
      }
    },
    async deleteWorkingTime() {
      if (!window.confirm('Supprimer cette session ?')) return
      this.isSaving = true
      this.errorMessage = ''
      try {
        await api.deleteWorkingTime(this.workingTimeID)
        await this.$router.push({ name: 'workingTimes', params: { userID: this.userID } })
      } catch {
        this.errorMessage = 'Impossible de supprimer cette session.'
      } finally {
        this.isSaving = false
      }
    },
    submit() { return this.isEditing ? this.updateWorkingTime() : this.createWorkingTime() }
  }
}
</script>

<template>
  <section class="working-time-page">
    <div class="working-time-header">
      <div>
        <p class="eyebrow">Gestion des pointages · utilisateur {{ userID }}</p>
        <h1>{{ title }}</h1>
        <p class="intro">Conserve des horaires précis pour garder un historique fiable.</p>
      </div>
      <router-link class="back-link" :to="{ name: 'workingTimes', params: { userID } }">Retour à l'historique</router-link>
    </div>

    <form class="working-time-form" @submit.prevent="submit">
      <p v-if="isLoading" class="form-message">Chargement de la session…</p>
      <p v-if="errorMessage" class="form-error" role="alert">{{ errorMessage }}</p>
      <label>Début <input v-model="form.start" type="datetime-local" required /></label>
      <label>Fin <input v-model="form.end" type="datetime-local" /></label>
      <div class="form-actions">
        <button class="primary-button" type="submit" :disabled="isLoading || isSaving">{{ isSaving ? 'Enregistrement…' : isEditing ? 'Enregistrer les modifications' : 'Créer la session' }}</button>
        <button v-if="isEditing" class="delete-button" type="button" :disabled="isSaving" @click="deleteWorkingTime">Supprimer</button>
      </div>
    </form>
  </section>
</template>

<style scoped>
.working-time-page { --ink: #252522; --muted: #716b64; --line: rgba(37, 33, 27, .14); --copper: #a7673c; width: min(100%, 760px); margin: 5rem auto 3rem; color: var(--ink); }
.working-time-header { display: flex; align-items: end; justify-content: space-between; gap: 2rem; padding-bottom: 2rem; border-bottom: 1px solid var(--line); }.eyebrow { margin: 0 0 .7rem; color: var(--copper); font-size: .7rem; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; }.working-time-header h1 { margin: 0; font-size: clamp(2.4rem, 7vw, 4.8rem); line-height: .95; letter-spacing: -.075em; }.intro { margin: 1rem 0 0; color: var(--muted); line-height: 1.6; }.back-link { color: var(--ink); font-size: .75rem; font-weight: 800; white-space: nowrap; }.working-time-form { display: grid; gap: 1.2rem; margin-top: 2rem; padding: 1.5rem; background: #fff; border: 1px solid var(--line); }.working-time-form label { display: grid; gap: .5rem; color: var(--muted); font-size: .75rem; font-weight: 800; text-transform: uppercase; }.working-time-form input { width: 100%; padding: .85rem; color: var(--ink); border: 1px solid var(--line); border-radius: 0; }.form-message, .form-error { margin: 0; color: var(--muted); font-size: .8rem; }.form-error { color: #b6444d; }.form-actions { display: flex; gap: .75rem; flex-wrap: wrap; }.primary-button, .delete-button { min-height: 42px; padding: .7rem 1rem; border: 1px solid var(--ink); font-size: .75rem; font-weight: 800; cursor: pointer; }.primary-button { color: #fff; background: var(--ink); }.delete-button { color: #b6444d; background: #fff0f1; border-color: #e85d65; }.primary-button:disabled, .delete-button:disabled { cursor: wait; opacity: .55; }
@media (max-width: 680px) { .working-time-page { width: min(100% - 1rem, 760px); margin-top: 3rem; }.working-time-header { display: block; }.back-link { display: inline-block; margin-top: 1.5rem; } }
</style>
