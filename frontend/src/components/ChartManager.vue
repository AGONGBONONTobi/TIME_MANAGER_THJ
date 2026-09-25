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
  <div class="container mt-4">
    <h1 class="mb-4">📊 Tableau de bord</h1>

    <div v-if="loading" class="alert alert-info">
      Chargement des graphiques...
    </div>

    <div v-if="error" class="alert alert-danger">
      {{ error }}
    </div>

    <div v-if="!loading && !error && workingtimes.length === 0" class="alert alert-warning">
      Aucune donnée de temps de travail pour cet utilisateur.
    </div>

    <div v-if="!loading && !error && workingtimes.length > 0">
      <!-- Graphique 1 : BAR (pleine largeur) -->
      <div class="row mb-4">
        <div class="col-12">
          <div class="card shadow-sm">
            <div class="card-header bg-primary text-white">
              <h5 class="mb-0">📈 Heures travaillées par jour de la semaine</h5>
            </div>
            <div class="card-body">
              <Bar :data="barData" :options="chartOptions" />
            </div>
          </div>
        </div>
      </div>

      <!-- Graphiques 2 et 3 (côte à côte) -->
      <div class="row">
        <div class="col-md-6 mb-4">
          <div class="card shadow-sm h-100">
            <div class="card-header bg-success text-white">
              <h5 class="mb-0">🥧 Répartition par jour</h5>
            </div>
            <div class="card-body d-flex align-items-center justify-content-center">
              <Pie :data="pieData" :options="chartOptions" />
            </div>
          </div>
        </div>

        <div class="col-md-6 mb-4">
          <div class="card shadow-sm h-100">
            <div class="card-header bg-warning text-dark">
              <h5 class="mb-0">📉 Évolution sur le mois</h5>
            </div>
            <div class="card-body">
              <LineChart :data="lineData" :options="chartOptions" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.card {
  border-radius: 8px;
}

.card-header {
  border-radius: 8px 8px 0 0 !important;
}
</style>
