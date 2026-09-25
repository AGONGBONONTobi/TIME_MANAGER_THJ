<script>
import api from '../services/api'

export default {
  name: 'ClockManager',
  props: ['userID'],
  data() {
    return {
      clock: null,
      time: '',
      clockIn: false,
      lastTime: false
    }
  },
  mounted() {
    this.refresh()
  },
  methods: {
    // Convert "2026-09-25T14:30" (local, no seconds) to UTC ISO with seconds
    toUtcIso(localDateTime) {
      if (!localDateTime) return null
      const d = new Date(localDateTime)
      return d.toISOString() // "2026-09-25T12:30:00.000Z"
    },

    async createClock() {
      if (!this.userID) return alert('Aucun utilisateur')
      if (!this.time) return alert('Choisis une heure')
      try {
        const res = await api.post(`/clocks/${this.userID}`, {
          time: this.toUtcIso(this.time),
          status: this.status
        })
        this.clock = res.data.data
        this.time = this.clock.time
        this.clockIn = this.clock.status
        alert('Clock enregistré')
      } catch (err) {
        console.error(err)
        alert('Erreur lors du pointage')
      }
    },
  async refresh() {
      if (!this.userID) return
      try {
        const res = await api.get(`/clocks/${this.userID}`)
        this.clockIn = res.data.data.status
      } catch (err) {
        console.error(err)
      }
    }
  }
}
</script>

<template>
  <div class="card p-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h2>⏰ Clocks (User {{ userID }})</h2>
      <button
        class="btn"
        :class="clockIn ? 'btn-danger' : 'btn-success'"
        @click="clock"
      >
        {{ clockIn ? '🔴 Pointer la sortie' : '🟢 Pointer l\'entrée' }}
      </button>
    </div>

    <div class="d-flex gap-2 mb-3">
      <button class="btn btn-outline-primary" @click="refresh">
        🔄 Rafraîchir
      </button>
      <span v-if="clockIn" class="badge bg-success align-self-center">
        Pointage en cours depuis {{ lastClock ? lastClock.time : '—' }}
      </span>
      <span v-else class="badge bg-secondary align-self-center">
        Aucun pointage en cours
      </span>
    </div>

    <table class="table table-striped" v-if="clocks.length">
      <thead>
        <tr>
          <th>ID</th>
          <th>Heure</th>
          <th>Statut</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="c in sortedClocks" :key="c.id">
          <td>{{ c.id }}</td>
          <td>{{ formatTime(c.time) }}</td>
          <td>
            <span
              class="badge"
              :class="c.status ? 'bg-success' : 'bg-secondary'"
            >
              {{ c.status ? 'in' : 'out' }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else class="text-muted">Aucun pointage enregistré.</p>
  </div>
</template>


<style scoped>
</style>
