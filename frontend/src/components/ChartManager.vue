<!-- src/components/ChartManager.vue -->
<script>
import { Bar, Pie, Line as LineChart } from 'vue-chartjs'
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
  ArcElement,
  PointElement,
  LineElement,
  Filler
} from 'chart.js'
import api from '../services/api'

// Enregistrement des modules Chart.js
ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
  ArcElement,
  PointElement,
  LineElement,
  Filler
)

export default {
  name: 'ChartManager',
  components: {
    Bar,
    Pie,
    LineChart
  },
  data() {
    return {
      loading: true,
      error: '',
      workingtimes: [],
      barData: null,
      pieData: null,
      lineData: null,
      chartOptions: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            position: 'top'
          }
        }
      }
    }
  },
  mounted() {
    this.fetchWorkingTimes()
  },
  methods: {
    async fetchWorkingTimes() {
      const userID = this.$route.params.userID
      if (!userID) {
        this.error = 'Aucun user ID fourni'
        this.loading = false
        return
      }

      try {
        const response = await api.getWorkingTimes(userID)
        this.workingtimes = response.data.data || []
        this.buildCharts()
        this.loading = false
      } catch (err) {
        this.error = 'Impossible de charger les données'
        this.loading = false
        console.error(err)
      }
    },

    hoursBetween(start, end) {
      return (new Date(end) - new Date(start)) / (1000 * 60 * 60)
    },

    getDayIndex(dateString) {
      const day = new Date(dateString).getDay()
      // JS: 0 = dimanche, 1 = lundi, ...
      // On veut : 0 = lundi, ..., 6 = dimanche
      return day === 0 ? 6 : day - 1
    },

    // Calcul : heures par jour de la semaine
    computeHoursByDay() {
      const totals = [0, 0, 0, 0, 0, 0, 0]
      this.workingtimes.forEach(wt => {
        if (!wt.end) return
        const idx = this.getDayIndex(wt.start)
        totals[idx] += this.hoursBetween(wt.start, wt.end)
      })
      return totals.map(h => Math.round(h * 10) / 10) // arrondi 1 décimale
    },

    // Calcul : heures par jour du mois (dates réelles)
    computeHoursByDate() {
      const daily = {}
      this.workingtimes.forEach(wt => {
        if (!wt.end) return
        const day = wt.start.split('T')[0]
        daily[day] = (daily[day] || 0) + this.hoursBetween(wt.start, wt.end)
      })

      const sortedDays = Object.keys(daily).sort()
      const values = sortedDays.map(d => Math.round(daily[d] * 10) / 10)

      return { labels: sortedDays, values }
    },

    buildCharts() {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
      const hoursByDay = this.computeHoursByDay()

      // Graphique 1 — BAR
      this.barData = {
        labels: days,
        datasets: [
          {
            label: 'Heures travaillées',
            data: hoursByDay,
            backgroundColor: '#3b82f6',
            borderColor: '#2563eb',
            borderWidth: 1,
            borderRadius: 4
          }
        ]
      }

      // Graphique 2 — PIE
      this.pieData = {
        labels: days,
        datasets: [
          {
            data: hoursByDay,
            backgroundColor: [
              '#3b82f6', // bleu
              '#10b981', // vert
              '#f59e0b', // orange
              '#ef4444', // rouge
              '#8b5cf6', // violet
              '#ec4899', // rose
              '#06b6d4'  // cyan
            ],
            borderColor: '#fff',
            borderWidth: 2
          }
        ]
      }

      // Graphique 3 — LINE
      const byDate = this.computeHoursByDate()
      this.lineData = {
        labels: byDate.labels,
        datasets: [
          {
            label: 'Heures par jour',
            data: byDate.values,
            borderColor: '#3b82f6',
            backgroundColor: 'rgba(59, 130, 246, 0.15)',
            tension: 0.3,
            fill: true,
            pointBackgroundColor: '#3b82f6',
            pointBorderColor: '#fff',
            pointRadius: 4
          }
        ]
      }
    }
  }
}
</script>

<template>
  <section class="charts-page">
    <header class="charts-header">
      <div>
        <p class="eyebrow">ANALYSE PERSONNELLE · UTILISATEUR {{ $route.params.userID }}</p>
        <h1>Vos heures, <em>en clair.</em></h1>
        <p>Une lecture simple de vos rythmes de travail, sans masquer les jours de nuit.</p>
      </div>
      <router-link class="back-link" :to="{ name: 'user' }">Retour au tableau de bord</router-link>
    </header>

    <p v-if="loading" class="state-card" role="status">Chargement des graphiques…</p>
    <p v-if="error" class="state-card error" role="alert">{{ error }}</p>
    <p v-if="!loading && !error && workingtimes.length === 0" class="state-card">Aucune donnée de temps de travail pour cet utilisateur.</p>

    <div v-if="!loading && !error && workingtimes.length > 0" class="charts-grid">
      <article class="chart-card chart-card-wide">
        <div class="chart-card-heading"><div><p class="card-kicker">VOLUME HEBDOMADAIRE</p><h2>Heures travaillées par jour</h2></div><span class="chart-badge">Barres</span></div>
        <div class="chart-canvas" role="img" aria-label="Graphique des heures travaillées par jour de la semaine"><Bar :data="barData" :options="chartOptions" /></div>
      </article>
      <article class="chart-card">
        <div class="chart-card-heading"><div><p class="card-kicker">RÉPARTITION</p><h2>Part de chaque jour</h2></div><span class="chart-badge">Répartition</span></div>
        <div class="chart-canvas chart-canvas-pie" role="img" aria-label="Graphique de répartition des heures par jour"><Pie :data="pieData" :options="chartOptions" /></div>
      </article>
      <article class="chart-card">
        <div class="chart-card-heading"><div><p class="card-kicker">ÉVOLUTION</p><h2>Rythme au fil des dates</h2></div><span class="chart-badge">Ligne</span></div>
        <div class="chart-canvas" role="img" aria-label="Graphique de l'évolution des heures par date"><LineChart :data="lineData" :options="chartOptions" /></div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.charts-page { --ink: #252522; --muted: #716b64; --line: rgba(37, 33, 27, .14); --copper: #a7673c; width: min(100%, 1120px); margin: 4rem auto 3rem; color: var(--ink); }.charts-header { display: flex; align-items: end; justify-content: space-between; gap: 2rem; padding-bottom: 2rem; border-bottom: 1px solid var(--line); }.eyebrow, .card-kicker { margin: 0 0 .7rem; color: var(--copper); font-size: .7rem; font-weight: 800; letter-spacing: .14em; }.charts-header h1 { margin: 0; font-size: clamp(2.7rem, 7vw, 5.8rem); line-height: .92; letter-spacing: -.075em; }.charts-header h1 em { color: var(--copper); font-family: Georgia, serif; font-weight: 400; }.charts-header p:not(.eyebrow) { max-width: 520px; margin: 1rem 0 0; color: var(--muted); line-height: 1.6; }.back-link { color: var(--ink); font-size: .75rem; font-weight: 800; white-space: nowrap; }.state-card { margin: 2rem 0 0; padding: 1.2rem; color: var(--muted); background: #fff; border: 1px solid var(--line); }.state-card.error { color: #b6444d; border-left: 3px solid #e85d65; }.charts-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; margin-top: 2rem; }.chart-card { min-width: 0; padding: 1.35rem; background: #fff; border: 1px solid var(--line); box-shadow: 0 12px 30px rgba(37, 33, 27, .05); }.chart-card-wide { grid-column: 1 / -1; }.chart-card-heading { display: flex; align-items: start; justify-content: space-between; gap: 1rem; }.chart-card h2 { margin: 0; font-size: 1.15rem; letter-spacing: -.04em; }.chart-card .card-kicker { margin-bottom: .4rem; }.chart-badge { padding: .35rem .55rem; color: #786be7; background: #f1efff; border-radius: 99px; font-size: .65rem; font-weight: 800; white-space: nowrap; }.chart-canvas { min-height: 270px; margin-top: 1.3rem; }.chart-canvas-pie { display: grid; place-items: center; }.chart-canvas :deep(canvas) { max-width: 100%; }
@media (max-width: 760px) { .charts-page { width: min(100% - 1rem, 1120px); margin-top: 2.5rem; }.charts-header { display: block; }.back-link { display: inline-block; margin-top: 1.5rem; }.charts-grid { grid-template-columns: 1fr; }.chart-card-wide { grid-column: auto; } }
</style>
