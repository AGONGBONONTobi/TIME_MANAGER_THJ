<script>
import api from '../services/api'
import { readAuthUser } from '../utils/auth'

export default {
  name: 'ClockManager',
  props: { userID: { type: [String, Number], required: true } },
  data() {
    return {
      clocks: [],
      startDateTime: null,
      clockIn: false,
      isLoading: false,
      isClocking: false,
      errorMessage: '',
      userName: '',
      showCorrectionForm: false,
      correctionForm: {
        date: '',
        time: '',
        status: true,
        reason: ''
      },
      correctionMessage: ''
    }
  },
  mounted() { this.loadUserName(); this.refresh() },
  methods: {
    async loadUserName() {
      try {
        const response = await api.getUser(this.userID)
        this.userName = response.data?.data?.username || response.data?.username || readAuthUser()?.username || `Utilisateur #${this.userID}`
      } catch {
        this.userName = readAuthUser()?.username || `Utilisateur #${this.userID}`
      }
    },
    async refresh() {
      this.isLoading = true
      this.errorMessage = ''
      try {
        const response = await api.getClocks(this.userID)
        this.clocks = response.data.data || []
        const latestClock = this.clocks[0]
        this.clockIn = Boolean(latestClock?.status)
        this.startDateTime = this.clockIn ? latestClock.time : null
      } catch {
        this.errorMessage = 'Impossible de charger les pointages.'
      } finally {
        this.isLoading = false
      }
    },
    async clock() {
      this.isClocking = true
      this.errorMessage = ''
      this.correctionMessage = ''
      try {
        await api.clockInOut(this.userID)
        await this.refresh()
      } catch (error) {
        this.errorMessage = error.response?.data?.error === 'already clocked in'
          ? 'Une session est déjà en cours.'
          : 'Le pointage n’a pas pu être enregistré.'
      } finally {
        this.isClocking = false
      }
    },
    async submitCorrection() {
      this.isLoading = true
      this.errorMessage = ''
      this.correctionMessage = ''
      try {
        const datetime = new Date(`${this.correctionForm.date}T${this.correctionForm.time}`).toISOString()
        const payload = {
          proposed_time: datetime,
          proposed_status: this.correctionForm.status,
          reason: this.correctionForm.reason,
          status: 'pending'
        }
        await api.createClockCorrection(payload)
        this.showCorrectionForm = false
        this.correctionForm = { date: '', time: '', status: true, reason: '' }
        this.correctionMessage = 'Demande de correction envoyée avec succès.'
      } catch (error) {
        this.errorMessage = 'Erreur lors de l\'envoi de la demande.'
      } finally {
        this.isLoading = false
      }
    },
    formatDateTime(value) {
      return value ? new Intl.DateTimeFormat('fr-FR', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) : '—'
    }
  }
}
</script>

<template>
  <section class="clock-page">
    <div class="clock-header">
      <div>
        <p class="eyebrow">POINTAGE · <span v-if="userName">{{ userName }}</span><span v-else>Chargement…</span></p>
        <h1>Déclarer ses heures.</h1>
        <p class="intro">Le bouton alterne entre le début et la fin de votre période de travail.</p>
      </div>
      <router-link class="back-link" :to="{ name: 'user' }">Retour au tableau de bord</router-link>
    </div>
    <div class="clock-card">
      <span class="status-label">État actuel</span>
      <strong class="status" :class="{ active: clockIn }"><i></i>{{ clockIn ? 'En cours' : 'Au repos' }}</strong>
      <p v-if="clockIn">Session commencée le {{ formatDateTime(startDateTime) }}</p>
      <p v-else>Aucune période de travail en cours.</p>
      <p v-if="errorMessage" class="error" role="alert">{{ errorMessage }}</p>
      <p v-if="correctionMessage" class="success" role="alert">{{ correctionMessage }}</p>
      <div class="actions">
        <button class="clock-button" :class="{ stop: clockIn }" type="button" :disabled="isLoading || isClocking" @click="clock">{{ isClocking ? 'Enregistrement…' : clockIn ? 'Clock Out' : 'Clock In' }}</button>
        <button class="refresh-button" type="button" :disabled="isLoading" @click="refresh">Actualiser</button>
        <button class="forgot-button" type="button" @click="showCorrectionForm = !showCorrectionForm">Oubli de pointage ?</button>
      </div>
      
      <div v-if="showCorrectionForm" class="correction-form">
        <h4>Demander une correction</h4>
        <div class="form-group">
          <label>Date :</label>
          <input type="date" v-model="correctionForm.date" required />
        </div>
        <div class="form-group">
          <label>Heure :</label>
          <input type="time" v-model="correctionForm.time" required />
        </div>
        <div class="form-group">
          <label>Type :</label>
          <select v-model="correctionForm.status">
            <option :value="true">Début de service (Clock In)</option>
            <option :value="false">Fin de service (Clock Out)</option>
          </select>
        </div>
        <div class="form-group">
          <label>Raison :</label>
          <textarea v-model="correctionForm.reason" rows="2" placeholder="Expliquez brièvement l'oubli" required></textarea>
        </div>
        <button class="submit-correction" type="button" :disabled="isLoading || !correctionForm.date || !correctionForm.time || !correctionForm.reason" @click="submitCorrection">Envoyer la demande</button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.clock-page { --ink: #252522; --muted: #716b64; --line: rgba(37, 33, 27, .14); --copper: #786be7; width: min(100%, 760px); margin: 0 auto; color: var(--ink); }.clock-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 2rem; padding-bottom: 1.5rem; margin-bottom: 1.5rem; border-bottom: 1px solid var(--line); }.eyebrow { margin: 0 0 8px; color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; text-transform: uppercase; }.clock-header h1 { margin: 0; font: 800 clamp(25px, 3.5vw, 34px) 'Manrope', sans-serif; letter-spacing: -.055em; line-height: 1.1; }.intro { max-width: 500px; margin: 8px 0 0; color: var(--muted); font-size: 13px; line-height: 1.6; }.back-link { color: var(--ink); font-size: .75rem; font-weight: 800; white-space: nowrap; flex-shrink: 0; }.clock-card { display: grid; gap: .75rem; margin-top: 2rem; padding: 2rem; background: #fff; border: 1px solid var(--line); border-radius: 12px; }.status-label { color: var(--muted); font-size: .7rem; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; }.status { display: flex; align-items: center; gap: .5rem; font-size: 1.5rem; }.status i { width: 10px; height: 10px; background: #96918a; border-radius: 50%; }.status.active { color: #638b63; }.status.active i { background: #638b63; box-shadow: 0 0 0 5px rgba(99, 139, 99, .15); }.clock-card p { margin: 0; color: var(--muted); font-size: .85rem; }.error { color: #b6444d !important; }.success { color: #47ad79 !important; }.actions { display: flex; gap: .75rem; margin-top: .75rem; flex-wrap: wrap; }.clock-button, .refresh-button, .forgot-button, .submit-correction { min-height: 42px; padding: .7rem 1rem; font-size: .75rem; font-weight: 800; cursor: pointer; border-radius: 8px; }.clock-button { color: #fff; background: #47ad79; border: 1px solid #47ad79; }.clock-button.stop { background: #e85d65; border-color: #e85d65; }.refresh-button { color: var(--ink); background: transparent; border: 1px solid var(--line); }.forgot-button { color: var(--copper); background: transparent; border: 1px dashed var(--copper); margin-left: auto; }.submit-correction { background: var(--copper); color: white; border: none; width: 100%; margin-top: 1rem; }.clock-button:disabled, .refresh-button:disabled, .submit-correction:disabled { cursor: wait; opacity: .55; }
.correction-form { margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid var(--line); }
.correction-form h4 { margin: 0 0 1rem; font-size: 1rem; }
.form-group { margin-bottom: 1rem; display: flex; flex-direction: column; gap: 4px; }
.form-group label { font-size: .75rem; font-weight: 800; color: var(--muted); text-transform: uppercase; letter-spacing: .05em; }
.form-group input, .form-group select, .form-group textarea { padding: .5rem; border: 1px solid var(--line); border-radius: 6px; font-family: inherit; font-size: .85rem; }

@media (max-width: 680px) { .clock-page { width: min(100% - 1rem, 760px); margin-top: 3rem; }.clock-header { display: block; }.back-link { display: inline-block; margin-top: 1.5rem; } }
</style>
