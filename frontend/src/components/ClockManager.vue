<!-- src/components/ClockManager.vue -->
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
        Pointage en cours depuis {{ lastClock ? formatTime(lastClock.time) : '—' }}
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

<script>
import api from '../services/api'

export default {
  name: 'ClockManager',
  props: ['userID'],
  data() {
    return {
      clocks: []
    }
  },
  computed: {
    sortedClocks() {
      return [...this.clocks].sort(
        (a, b) => new Date(b.time) - new Date(a.time)
      )
    },
    lastClock() {
      return this.sortedClocks[0] || null
    },
    clockIn() {
      return this.lastClock ? this.lastClock.status === true : false
    }
  },
  mounted() {
    this.refresh()
  },
  methods: {
    formatTime(iso) {
      if (!iso) return '—'
      return new Date(iso).toLocaleString()
    },

    async refresh() {
      if (!this.userID) return
      try {
        const res = await api.get(`/clocks/${this.userID}`)
        this.clocks = res.data?.data ?? []
      } catch (err) {
        console.error(err)
        this.clocks = []
      }
    },

    async clock() {
      if (!this.userID) return alert('Aucun utilisateur')
      try {
        await api.post(`/clocks/${this.userID}`, {
          time: new Date().toISOString(),
          status: !this.clockIn
        })
        await this.refresh()
      } catch (err) {
        console.error(err)
        alert('Erreur lors du pointage')
      }
    }
  }
}
</script>

<style scoped>
</style>
