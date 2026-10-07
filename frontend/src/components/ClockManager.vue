<script>
import api from '../services/api'
import { readAuthUser } from '../utils/auth'
import { queueClockEvent, synchronisePendingEvents } from '../services/syncService'
import { isOnline } from '../services/networkService'

export default {
  name: 'ClockManager',
  props: { userID: { type: [String, Number], required: true } },
  data() {
    return { clocks: [], startDateTime: null, clockIn: false, isLoading: false, isClocking: false, errorMessage: '', userName: '', isOnline: isOnline(), pendingSync: false, removeNetworkListener: null }
  },
  mounted() {
    this.loadUserName()
    this.refresh()
    this.removeNetworkListener = () => {
      window.removeEventListener('time-manager-network', this.onNetworkChange)
      window.removeEventListener('time-manager-sync', this.refresh)
    }
    window.addEventListener('time-manager-network', this.onNetworkChange)
    window.addEventListener('time-manager-sync', this.refresh)
  },
  beforeUnmount() { this.removeNetworkListener?.() },
  methods: {
    onNetworkChange(event) {
      this.isOnline = event.detail.online
      if (this.isOnline) synchronisePendingEvents()
    },
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
      try {
        const eventType = this.clockIn ? 'clock_out' : 'clock_in'
        const occurredAt = new Date().toISOString()
        if (!this.isOnline) {
          await queueClockEvent({ userId: this.userID, eventType, occurredAt })
          this.clockIn = eventType === 'clock_in'
          this.startDateTime = this.clockIn ? occurredAt : null
          this.errorMessage = 'Pointage enregistré hors ligne. Il sera synchronisé automatiquement.'
          return
        }
        await api.clockInOut(this.userID, { event_type: eventType, occurred_at: occurredAt })
        await this.refresh()
      } catch (error) {
        this.errorMessage = error.response?.data?.error === 'already clocked in'
          ? 'Une session est déjà en cours.'
          : 'Le pointage n’a pas pu être enregistré.'
      } finally {
        this.isClocking = false
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
      <p class="network-status" :class="{ offline: !isOnline }">{{ isOnline ? 'En ligne' : 'Hors ligne' }}</p>
      <p v-if="errorMessage" class="error" role="alert">{{ errorMessage }}</p>
      <div class="actions">
        <button class="clock-button" :class="{ stop: clockIn }" type="button" :disabled="isLoading || isClocking" @click="clock">{{ isClocking ? 'Enregistrement…' : clockIn ? 'Clock Out' : 'Clock In' }}</button>
        <button class="refresh-button" type="button" :disabled="isLoading" @click="refresh">Actualiser</button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.clock-page { --ink: #252522; --muted: #716b64; --line: rgba(37, 33, 27, .14); --copper: #786be7; width: min(100%, 760px); margin: 0 auto; color: var(--ink); }.clock-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 2rem; padding-bottom: 1.5rem; margin-bottom: 1.5rem; border-bottom: 1px solid var(--line); }.eyebrow { margin: 0 0 8px; color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; text-transform: uppercase; }.clock-header h1 { margin: 0; font: 800 clamp(25px, 3.5vw, 34px) 'Manrope', sans-serif; letter-spacing: -.055em; line-height: 1.1; }.intro { max-width: 500px; margin: 8px 0 0; color: var(--muted); font-size: 13px; line-height: 1.6; }.back-link { color: var(--ink); font-size: .75rem; font-weight: 800; white-space: nowrap; flex-shrink: 0; }.clock-card { display: grid; gap: .75rem; margin-top: 2rem; padding: 2rem; background: #fff; border: 1px solid var(--line); border-radius: 12px; }.status-label { color: var(--muted); font-size: .7rem; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; }.status { display: flex; align-items: center; gap: .5rem; font-size: 1.5rem; }.status i { width: 10px; height: 10px; background: #96918a; border-radius: 50%; }.status.active { color: #638b63; }.status.active i { background: #638b63; box-shadow: 0 0 0 5px rgba(99, 139, 99, .15); }.clock-card p { margin: 0; color: var(--muted); font-size: .85rem; }.error { color: #b6444d !important; }.actions { display: flex; gap: .75rem; margin-top: .75rem; }.clock-button, .refresh-button { min-height: 42px; padding: .7rem 1rem; font-size: .75rem; font-weight: 800; cursor: pointer; border-radius: 8px; }.clock-button { color: #fff; background: #47ad79; border: 1px solid #47ad79; }.clock-button.stop { background: #e85d65; border-color: #e85d65; }.refresh-button { color: var(--ink); background: transparent; border: 1px solid var(--line); }.clock-button:disabled, .refresh-button:disabled { cursor: wait; opacity: .55; }
.network-status { width: fit-content; padding: 4px 8px; color: #276749 !important; background: #f0fff4; border-radius: 999px; font-size: .7rem !important; font-weight: 800; }.network-status.offline { color: #9b2c2c !important; background: #fff5f5; }
@media (max-width: 680px) { .clock-page { width: min(100% - 1rem, 760px); margin-top: 3rem; }.clock-header { display: block; }.back-link { display: inline-block; margin-top: 1.5rem; } }
</style>
