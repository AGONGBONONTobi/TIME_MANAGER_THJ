<script>
export default {
  name: 'ManagerDashboard',
  data() {
    return {
      now: new Date(),
      timerId: null,
      selectedIds: [],
      employees: [
        { id: 1, name: 'Joseph Martin',    role: 'Développeur', hours: 38.5, nights: 4, validated: false, missedClock: false },
        { id: 2, name: 'Amélie Rousseau',  role: 'Designer',    hours: 35.0, nights: 1, validated: true,  missedClock: false },
        { id: 3, name: 'Karim Benali',     role: 'Support',     hours: 32.5, nights: 5, validated: false, missedClock: true  },
        { id: 4, name: 'Sophie Laurent',   role: 'Manager',     hours: 40.0, nights: 0, validated: true,  missedClock: false },
        { id: 5, name: 'Thomas Petit',     role: 'Commercial',  hours: 28.0, nights: 2, validated: false, missedClock: true  }
      ]
    }
  },
  computed: {
    todayLabel() {
      return new Intl.DateTimeFormat('fr-FR', {
        weekday: 'long', day: '2-digit', month: 'long', year: 'numeric'
      }).format(this.now)
    },
    teamSize()     { return this.employees.length },
    pendingCount() { return this.employees.filter(e => !e.validated).length },
    totalNights()  { return this.employees.reduce((t, e) => t + e.nights, 0) },
    missedCount()  { return this.employees.filter(e => e.missedClock).length },
    alerts()       { return this.employees.filter(e => e.nights > 3) },
    selectedCount(){ return this.selectedIds.length },
    maxHours()     { return Math.max(...this.employees.map(e => e.hours), 35) },
    allSelected()  { return this.employees.length > 0 && this.selectedIds.length === this.employees.length }
  },
  mounted() {
    this.timerId = window.setInterval(() => { this.now = new Date() }, 60000)
  },
  beforeUnmount() {
    window.clearInterval(this.timerId)
  },
  methods: {
    toggleSelect(id) {
      const i = this.selectedIds.indexOf(id)
      if (i === -1) this.selectedIds.push(id)
      else this.selectedIds.splice(i, 1)
    },
    isSelected(id) { return this.selectedIds.includes(id) },
    toggleSelectAll() {
      this.selectedIds = this.allSelected ? [] : this.employees.map(e => e.id)
    },
    validateSelection() {
      this.employees.forEach(e => { if (this.selectedIds.includes(e.id)) e.validated = true })
      this.selectedIds = []
    },
    validateAll() {
      this.employees.forEach(e => { e.validated = true })
      this.selectedIds = []
    },
    barWidth(hours) { return `${Math.min(100, (hours / this.maxHours) * 100)}%` },
    remind(employee) {
      window.alert(`Relance envoyée à ${employee.name} pour son oubli de pointage.`)
    }
  }
}
</script>

<template>
  <section class="dashboard-page">
    <div class="welcome-row">
      <div>
        <p class="dashboard-kicker">TABLEAU DE BORD MANAGER</p>
        <h1>Bonjour, Manager</h1>
        <p class="dashboard-date">{{ todayLabel }}</p>
      </div>
    </div>

    <!-- Alertes automatiques : nuits > 3 -->
    <div v-if="alerts.length" class="alert-banner" role="alert">
      <span class="alert-icon">⚠️</span>
      <div>
        <strong>Alerte — dépassement du seuil de nuits travaillées</strong>
        <ul>
          <li v-for="emp in alerts" :key="emp.id">
            <b>{{ emp.name }}</b> — {{ emp.nights }} nuits cette semaine (seuil autorisé : 3)
          </li>
        </ul>
      </div>
    </div>

    <!-- 4 stats globales -->
    <div class="stats-grid">
      <article class="stat-card blue">
        <span class="stat-icon">👥</span>
        <p>Membres de l'équipe</p>
        <strong>{{ teamSize }}</strong>
      </article>
      <article class="stat-card amber">
        <span class="stat-icon">⏳</span>
        <p>Timesheets en attente</p>
        <strong>{{ pendingCount }}</strong>
      </article>
      <article class="stat-card violet">
        <span class="stat-icon">🌙</span>
        <p>Nuits travaillées (semaine)</p>
        <strong>{{ totalNights }}</strong>
      </article>
      <article class="stat-card red">
        <span class="stat-icon">⚠️</span>
        <p>Oublis de pointage</p>
        <strong>{{ missedCount }}</strong>
      </article>
    </div>

    <!-- Tableau de l'équipe -->
    <section class="team-section">
      <div class="section-title">
        <div>
          <p class="card-kicker">ÉQUIPE</p>
          <h2>Suivi des timesheets</h2>
        </div>
        <div class="actions">
          <button
            class="btn-secondary"
            type="button"
            :disabled="!selectedCount"
            @click="validateSelection"
          >
            Valider la sélection ({{ selectedCount }})
          </button>
          <button
            class="btn-primary"
            type="button"
            :disabled="!pendingCount"
            @click="validateAll"
          >
            Valider tout
          </button>
        </div>
      </div>

      <div class="table-wrap">
        <div class="team-table head">
          <span>
            <input
              type="checkbox"
              :checked="allSelected"
              @change="toggleSelectAll"
              aria-label="Tout sélectionner"
            />
          </span>
          <span>Nom</span>
          <span>Heures</span>
          <span>Nuits</span>
          <span>Statut</span>
          <span>Actions</span>
        </div>

        <div v-for="emp in employees" :key="emp.id" class="team-table">
          <span>
            <input
              type="checkbox"
              :checked="isSelected(emp.id)"
              @change="toggleSelect(emp.id)"
              :aria-label="`Sélectionner ${emp.name}`"
            />
          </span>
          <span class="cell-name">
            <b>{{ emp.name }}</b>
            <small>{{ emp.role }}</small>
            <b v-if="emp.missedClock" class="badge-missed">⚠️ Oubli de pointage</b>
          </span>
          <span><b>{{ emp.hours.toFixed(1) }} h</b></span>
          <span>
            <b class="badge-nights" :class="{ danger: emp.nights > 3 }">
              🌙 {{ emp.nights }}
            </b>
          </span>
          <span>
            <b class="row-status" :class="{ pending: !emp.validated }">
              {{ emp.validated ? '✅ Validé' : '⏳ En attente' }}
            </b>
          </span>
          <span class="cell-actions">
            <button type="button" class="link-btn">Voir</button>
            <button
              v-if="emp.missedClock"
              type="button"
              class="link-btn danger"
              @click="remind(emp)"
            >
              Relancer
            </button>
          </span>
        </div>
      </div>
    </section>

    <!-- Graphique à barres horizontales -->
    <section class="chart-section">
      <div class="section-title">
        <div>
          <p class="card-kicker">HEURES TRAVAILLÉES</p>
          <h2>Répartition par employé</h2>
        </div>
      </div>

      <div class="bar-chart">
        <div v-for="emp in employees" :key="emp.id" class="bar-row">
          <span class="bar-label">{{ emp.name }}</span>
          <div class="bar-track">
            <div class="bar-fill" :style="{ width: barWidth(emp.hours) }">
              <span>{{ emp.hours.toFixed(1) }} h</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  </section>
</template>

<style scoped>
.dashboard-page { max-width: 1120px; margin: 0 auto; color: #252b38; }
.welcome-row, .section-title { display: flex; align-items: flex-start; justify-content: space-between; gap: 18px; }
.welcome-row { align-items: flex-end; margin-bottom: 24px; }
.dashboard-kicker, .card-kicker { margin: 0 0 8px; color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; }
.welcome-row h1 { margin: 0; font: 800 clamp(25px, 4vw, 34px) 'Manrope', sans-serif; letter-spacing: -.055em; }
.dashboard-date { margin: 8px 0 0; color: #8c96a5; font-size: 13px; text-transform: capitalize; }

/* Alertes */
.alert-banner { display: flex; gap: 14px; align-items: flex-start; margin-bottom: 20px; padding: 16px 18px; background: #fff5f0; border-left: 4px solid #e85d65; border-radius: 10px; color: #7a3b40; }
.alert-banner .alert-icon { font-size: 20px; line-height: 1; }
.alert-banner strong { display: block; color: #b6444d; font-size: 13px; margin-bottom: 6px; }
.alert-banner ul { margin: 0; padding-left: 18px; font-size: 12px; }
.alert-banner b { color: #b6444d; }

/* Stats */
.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 20px; }
.stat-card { position: relative; padding: 18px; background: #fff; border: 1px solid #eaedf2; border-radius: 12px; overflow: hidden; box-shadow: 0 8px 25px #29375608; }
.stat-card .stat-icon { position: absolute; top: 14px; right: 16px; font-size: 18px; opacity: .85; }
.stat-card p { margin: 0 0 12px; color: #8c96a5; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; }
.stat-card strong { color: #293140; font: 800 28px 'Manrope', sans-serif; letter-spacing: -.04em; }
.stat-card::before { content: ''; position: absolute; inset: 0 0 auto; height: 3px; }
.stat-card.blue::before   { background: #5796e7; }
.stat-card.amber::before  { background: #f0ad32; }
.stat-card.violet::before { background: #8b7ded; }
.stat-card.red::before    { background: #e85d65; }

/* Sections */
.team-section, .chart-section { margin-top: 18px; padding: 24px; background: #fff; border: 1px solid #eaedf2; border-radius: 12px; box-shadow: 0 8px 25px #29375608; }
.section-title h2 { margin: 0; color: #293140; font: 700 17px 'Manrope', sans-serif; letter-spacing: -.035em; }
.actions { display: flex; gap: 10px; flex-wrap: wrap; }
.btn-primary, .btn-secondary { padding: 10px 16px; font-size: 12px; font-weight: 700; border-radius: 7px; cursor: pointer; border: 0; }
.btn-primary { color: #fff; background: #47ad79; }
.btn-secondary { color: #4c5666; background: #fff; border: 1px solid #e7eaf0; }
.btn-primary:disabled, .btn-secondary:disabled { opacity: .45; cursor: not-allowed; }

/* Tableau équipe */
.table-wrap { margin-top: 18px; overflow-x: auto; }
.team-table { display: grid; grid-template-columns: 36px 1.7fr .8fr .8fr 1fr 1.2fr; align-items: center; gap: 12px; min-width: 720px; min-height: 62px; padding: 0 4px; color: #5d6675; font-size: 12px; border-bottom: 1px solid #edf0f4; }
.team-table.head { min-height: 34px; color: #9aa3af; font-size: 10px; font-weight: 700; text-transform: uppercase; }
.team-table input[type="checkbox"] { width: 16px; height: 16px; accent-color: #786be7; cursor: pointer; }
.cell-name { display: flex; flex-direction: column; gap: 3px; }
.cell-name b { color: #303847; font-size: 12px; }
.cell-name small { color: #9aa3af; font-size: 10px; }
.badge-missed { display: inline-flex; align-items: center; gap: 4px; margin-top: 2px; padding: 2px 8px; color: #b6444d; font-size: 9px; font-weight: 700; background: #fff0f1; border-radius: 99px; width: fit-content; }
.badge-nights { display: inline-block; padding: 3px 9px; color: #4b3fc4; background: #ece9ff; border-radius: 99px; font-size: 11px; font-weight: 700; }
.badge-nights.danger { color: #b6444d; background: #fff0f1; }
.row-status { font-size: 11px; color: #43ae76; }
.row-status.pending { color: #e0a020; }
.cell-actions { display: flex; gap: 12px; }
.link-btn { padding: 0; color: #786be7; font-size: 11px; font-weight: 700; background: none; border: 0; cursor: pointer; }
.link-btn.danger { color: #e85d65; }
.link-btn:hover { text-decoration: underline; }

/* Graphique à barres */
.bar-chart { margin-top: 18px; display: flex; flex-direction: column; gap: 12px; }
.bar-row { display: grid; grid-template-columns: 150px 1fr; align-items: center; gap: 12px; }
.bar-label { color: #5d6675; font-size: 12px; font-weight: 600; }
.bar-track { position: relative; height: 26px; background: #f2f4f8; border-radius: 6px; overflow: hidden; }
.bar-fill { display: flex; align-items: center; justify-content: flex-end; height: 100%; padding-right: 10px; color: #fff; font-size: 11px; font-weight: 700; background: linear-gradient(90deg, #7c70e7, #5796e7); border-radius: 6px; transition: width .4s ease; min-width: 48px; }
.bar-fill span { white-space: nowrap; }

/* Responsive */
@media (max-width: 850px) { .stats-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 760px) {
  .welcome-row { display: block; }
  .section-title { flex-direction: column; align-items: stretch; }
  .bar-row { grid-template-columns: 110px 1fr; }
}
@media (max-width: 450px) {
  .stats-grid { grid-template-columns: 1fr; }
  .team-section, .chart-section { padding: 17px; }
  .bar-row { grid-template-columns: 90px 1fr; }
}
</style>
