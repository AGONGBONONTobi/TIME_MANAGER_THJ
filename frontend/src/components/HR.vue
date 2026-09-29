<script>
import api from '../services/api'

export default {
  name: 'HrDashboard',
  data() {
    return {
      users: [],
      sessions: [],
      search: '',
      statusFilter: 'all',
      isLoading: true,
      errorMessage: ''
    }
  },
  computed: {
    weekStart() {
      const date = new Date()
      const day = date.getDay() || 7
      date.setHours(0, 0, 0, 0)
      date.setDate(date.getDate() - day + 1)
      return date
    },
    employeeRows() {
      return this.users.map((user) => {
        const userSessions = this.sessions.filter((session) => session.user_id === user.id)
        const weekSessions = userSessions.filter((session) => new Date(session.start) >= this.weekStart)
        const minutes = weekSessions.reduce((total, session) => total + this.durationInMinutes(session), 0)
        const nightMinutes = weekSessions.filter((session) => this.isNightSession(session)).reduce((total, session) => total + this.durationInMinutes(session), 0)
        const activeSession = userSessions.find((session) => !session.end)
        const needsAttention = minutes > 35 * 60 || nightMinutes >= 18 * 60
        return {
          ...user,
          minutes,
          nightMinutes,
          activeSession,
          needsAttention,
          status: activeSession ? 'active' : needsAttention ? 'attention' : 'quiet'
        }
      })
    },
    filteredEmployees() {
      const query = this.search.trim().toLowerCase()
      return this.employeeRows.filter((employee) => {
        const matchesSearch = !query || `${employee.username} ${employee.email}`.toLowerCase().includes(query)
        const matchesStatus = this.statusFilter === 'all' || employee.status === this.statusFilter
        return matchesSearch && matchesStatus
      }).sort((a, b) => b.minutes - a.minutes)
    },
    totalHoursLabel() {
      const minutes = this.employeeRows.reduce((total, employee) => total + employee.minutes, 0)
      return `${(minutes / 60).toFixed(1)} h`
    },
    activeCount() { return this.employeeRows.filter((employee) => employee.activeSession).length },
    attentionCount() { return this.employeeRows.filter((employee) => employee.needsAttention).length },
    nightHoursLabel() {
      const minutes = this.employeeRows.reduce((total, employee) => total + employee.nightMinutes, 0)
      return `${(minutes / 60).toFixed(1)} h`
    },
    recentActivity() {
      return [...this.sessions].sort((a, b) => new Date(b.start) - new Date(a.start)).slice(0, 6).map((session) => ({
        ...session,
        user: this.users.find((user) => user.id === session.user_id)
      }))
    }
  },
  mounted() { this.loadDashboard() },
  methods: {
    async loadDashboard() {
      this.isLoading = true
      this.errorMessage = ''
      try {
        const response = await api.getUsers()
        this.users = response.data.data || []
        const responses = await Promise.all(this.users.map((user) => api.getWorkingTimes(user.id)))
        this.sessions = responses.flatMap((response) => response.data.data || [])
      } catch (error) {
        this.errorMessage = 'Impossible de charger les données RH. Vérifiez que l’API est démarrée.'
        console.error(error)
      } finally {
        this.isLoading = false
      }
    },
    durationInMinutes(session) { return Math.max(0, Math.round((new Date(session.end || new Date()) - new Date(session.start)) / 60000)) },
    isNightSession(session) { const hour = new Date(session.start).getHours(); return hour >= 21 || hour < 6 },
    formatDuration(minutes) { return minutes >= 60 ? `${Math.floor(minutes / 60)}h ${minutes % 60}m` : `${minutes} min` },
    formatDate(value) { return new Intl.DateTimeFormat('fr-FR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(value)) },
    employeeName(user) { return user?.username || 'Collaborateur inconnu' },
    exportCsv() {
      const header = ['Collaborateur', 'Email', 'Heures cette semaine', 'Heures de nuit', 'Statut']
      const lines = this.filteredEmployees.map((employee) => [employee.username, employee.email, (employee.minutes / 60).toFixed(2), (employee.nightMinutes / 60).toFixed(2), employee.activeSession ? 'En activité' : employee.needsAttention ? 'À vérifier' : 'À jour'])
      const csv = [header, ...lines].map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(';')).join('\n')
      const link = document.createElement('a')
      link.href = URL.createObjectURL(new Blob([`\ufeff${csv}`], { type: 'text/csv;charset=utf-8' }))
      link.download = 'rapport-rh.csv'
      link.click()
      URL.revokeObjectURL(link.href)
    }
  }
}
</script>

<template>
  <section class="hr-page">
    <div class="hr-header">
      <div><p class="dashboard-kicker">ESPACE RH / ADMINISTRATION</p><h1>Vue d’ensemble des équipes</h1><p class="dashboard-date">Suivi de la semaine en cours, actualisé depuis les pointages enregistrés.</p></div>
      <button class="export-button" type="button" :disabled="isLoading || !filteredEmployees.length" @click="exportCsv"><span>↓</span> Exporter le rapport</button>
    </div>
    <p v-if="errorMessage" class="api-error" role="alert">{{ errorMessage }} <button type="button" @click="loadDashboard">Réessayer</button></p>
    <div v-if="isLoading" class="loading-state">Chargement des données RH…</div>
    <template v-else>
      <section class="metric-grid" aria-label="Indicateurs RH">
        <article class="metric-card"><span class="metric-mark blue">◷</span><div><small>Collaborateurs</small><strong>{{ users.length }}</strong><p>référencés dans l’application</p></div></article>
        <article class="metric-card"><span class="metric-mark green">●</span><div><small>En activité</small><strong>{{ activeCount }}</strong><p>sessions actuellement ouvertes</p></div></article>
        <article class="metric-card"><span class="metric-mark amber">!</span><div><small>À vérifier</small><strong>{{ attentionCount }}</strong><p>seuil hebdomadaire ou nuit atteint</p></div></article>
        <article class="metric-card"><span class="metric-mark violet">⌁</span><div><small>Heures de nuit</small><strong>{{ nightHoursLabel }}</strong><p>cumul de la semaine</p></div></article>
      </section>
      <section class="team-section">
        <div class="section-title"><div><p class="card-kicker">SUIVI DES COLLABORATEURS</p><h2>{{ totalHoursLabel }} enregistrées cette semaine</h2></div><button class="refresh-link" type="button" :disabled="isLoading" @click="loadDashboard">Actualiser <span>↻</span></button></div>
        <div class="filters"><label class="search-field"><span>⌕</span><input v-model="search" type="search" placeholder="Rechercher un collaborateur…" /></label><select v-model="statusFilter" aria-label="Filtrer par statut"><option value="all">Tous les statuts</option><option value="active">En activité</option><option value="attention">À vérifier</option><option value="quiet">À jour</option></select></div>
        <div v-if="filteredEmployees.length" class="employee-table"><div class="employee-row employee-head"><span>Collaborateur</span><span>Temps cette semaine</span><span>Nuit</span><span>Statut</span></div><div v-for="employee in filteredEmployees" :key="employee.id" class="employee-row"><div class="employee-name"><span class="avatar">{{ employee.username.slice(0, 2).toUpperCase() }}</span><span><strong>{{ employee.username }}</strong><small>{{ employee.email }}</small></span></div><div><strong>{{ formatDuration(employee.minutes) }}</strong><div class="mini-progress"><i :style="{ width: `${Math.min(100, employee.minutes / 2100 * 100)}%` }"></i></div></div><span class="night-value">{{ formatDuration(employee.nightMinutes) }}</span><span class="status-label" :class="employee.status"><i></i>{{ employee.status === 'active' ? 'En activité' : employee.status === 'attention' ? 'À vérifier' : 'À jour' }}</span></div></div><div v-else class="empty-state"><strong>Aucun collaborateur trouvé</strong><p>Modifiez la recherche ou le filtre sélectionné.</p></div>
      </section>
      <section class="activity-section"><div class="section-title"><div><p class="card-kicker">JOURNAL RÉCENT</p><h2>Dernières activités</h2></div><span class="section-note">Lecture seule</span></div><div v-if="recentActivity.length" class="activity-list"><div v-for="session in recentActivity" :key="session.id" class="activity-row"><span class="activity-dot" :class="{ night: isNightSession(session) }"></span><div><strong>{{ employeeName(session.user) }}</strong><p>{{ session.end ? 'Session terminée' : 'Session en cours' }} · {{ formatDate(session.start) }}</p></div><span>{{ formatDuration(durationInMinutes(session)) }}</span></div></div><div v-else class="empty-state"><strong>Aucune activité récente</strong><p>Les pointages apparaîtront ici.</p></div></section>
    </template>
  </section>
</template>

<style scoped>
.hr-page { max-width: 1120px; margin: 0 auto; color: #252b38; }.hr-header, .section-title { display: flex; align-items: flex-start; justify-content: space-between; gap: 18px; }.hr-header { align-items: flex-end; margin-bottom: 30px; }.dashboard-kicker, .card-kicker { margin: 0 0 8px; color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; }.hr-header h1 { margin: 0; font: 800 clamp(25px, 4vw, 34px) 'Manrope', sans-serif; letter-spacing: -.055em; }.dashboard-date { margin: 8px 0 0; color: #8c96a5; font-size: 13px; }.export-button { display: inline-flex; align-items: center; gap: 9px; min-height: 42px; padding: 0 15px; color: #fff; font-size: 12px; font-weight: 700; background: #7368dc; border: 0; border-radius: 7px; cursor: pointer; }.export-button:disabled { cursor: not-allowed; opacity: .5; }.export-button span { font-size: 18px; }.api-error { margin: -10px 0 20px; padding: 11px 14px; color: #b6444d; font-size: 12px; background: #fff0f1; border-left: 3px solid #e85d65; }.api-error button { margin-left: 8px; color: inherit; font-weight: 700; background: none; border: 0; cursor: pointer; text-decoration: underline; }.loading-state, .empty-state { padding: 35px 0; color: #8c96a5; font-size: 12px; }.empty-state strong { color: #404959; font-size: 14px; }.empty-state p { margin-bottom: 0; }.metric-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 13px; }.metric-card, .team-section, .activity-section { background: #fff; border: 1px solid #eaedf2; border-radius: 12px; box-shadow: 0 8px 25px #29375608; }.metric-card { display: flex; align-items: flex-start; gap: 13px; min-height: 132px; padding: 19px; }.metric-mark { display: grid; width: 34px; height: 34px; flex: 0 0 auto; place-items: center; color: #fff; font-weight: 800; border-radius: 9px; }.metric-mark.blue { background: #5b91df; }.metric-mark.green { background: #48ae79; }.metric-mark.amber { background: #e8a72f; }.metric-mark.violet { background: #8b7ded; }.metric-card small, .metric-card p { display: block; color: #8c96a5; font-size: 10px; }.metric-card strong { display: block; margin-top: 9px; color: #303847; font: 800 25px 'Manrope', sans-serif; }.metric-card p { margin: 5px 0 0; line-height: 1.35; }.team-section, .activity-section { margin-top: 18px; padding: 23px; }.section-title h2 { margin: 0; color: #293140; font: 700 17px 'Manrope', sans-serif; letter-spacing: -.035em; }.refresh-link { color: #786be7; font-size: 11px; font-weight: 700; background: transparent; border: 0; cursor: pointer; }.refresh-link span { margin-left: 5px; font-size: 16px; }.section-note { color: #9aa3af; font-size: 11px; }.filters { display: flex; gap: 10px; margin: 22px 0 13px; }.search-field { display: flex; align-items: center; gap: 8px; min-width: 260px; flex: 1; padding: 0 12px; color: #9aa3af; border: 1px solid #e5e8ee; border-radius: 7px; }.search-field input { width: 100%; min-height: 39px; color: #394353; font-size: 12px; border: 0; outline: 0; }.filters select { min-width: 160px; padding: 0 12px; color: #4c5666; background: #fff; border: 1px solid #e5e8ee; border-radius: 7px; outline: 0; }.employee-table { overflow-x: auto; }.employee-row { display: grid; grid-template-columns: minmax(250px, 1.45fr) minmax(170px, 1fr) minmax(100px, .6fr) minmax(120px, .7fr); align-items: center; gap: 16px; min-width: 700px; min-height: 67px; color: #5d6675; font-size: 11px; border-bottom: 1px solid #edf0f4; }.employee-head { min-height: 36px; color: #9aa3af; font-size: 10px; font-weight: 700; text-transform: uppercase; }.employee-name { display: flex; align-items: center; gap: 10px; }.avatar { display: grid; width: 32px; height: 32px; place-items: center; color: #6659c9; font-size: 10px; font-weight: 800; background: #eeecff; border-radius: 50%; }.employee-name strong, .employee-name small { display: block; }.employee-name strong { color: #404959; }.employee-name small { margin-top: 3px; color: #9aa3af; font-size: 10px; }.mini-progress { width: 100%; height: 5px; margin-top: 8px; background: #edf0f4; border-radius: 99px; }.mini-progress i { display: block; height: 100%; background: #6f9de1; border-radius: inherit; }.night-value { color: #776bdd; font-weight: 700; }.status-label { display: inline-flex; align-items: center; gap: 6px; font-size: 10px; font-weight: 700; }.status-label i { width: 7px; height: 7px; background: #53a875; border-radius: 50%; }.status-label.active { color: #d84d5c; }.status-label.active i { background: #e85d65; }.status-label.attention { color: #bd8214; }.status-label.attention i { background: #e8a72f; }.status-label.quiet { color: #53a875; }.activity-list { margin-top: 10px; }.activity-row { display: flex; align-items: center; gap: 11px; min-height: 55px; border-bottom: 1px solid #edf0f4; }.activity-row > div { flex: 1; }.activity-row strong { color: #404959; font-size: 12px; }.activity-row p { margin: 4px 0 0; color: #9aa3af; font-size: 10px; }.activity-row > span:last-child { color: #4f5969; font-weight: 700; }.activity-dot { width: 8px; height: 8px; background: #53a875; border-radius: 50%; }.activity-dot.night { background: #776bdd; }
@media (max-width: 950px) { .metric-grid { grid-template-columns: repeat(2, 1fr); } } @media (max-width: 650px) { .hr-header { display: block; }.export-button { margin-top: 18px; }.filters { flex-direction: column; }.search-field { min-width: 0; min-height: 39px; }.metric-grid { grid-template-columns: 1fr; }.team-section, .activity-section { padding: 17px; } }
</style>
