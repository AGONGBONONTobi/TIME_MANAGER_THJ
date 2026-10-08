<script>
import api from '../services/api'
import { readAuthUser } from '../utils/auth'

export default {
  name: 'ManagerDashboard',
  data() {
    return {
      now: new Date(),
      timerId: null,
      selectedIds: [],
      currentUserName: readAuthUser()?.username || 'Manager',
      employees: [],
      teams: [],
      users: [],
      memberToAdd: {},
      selectedTeam: null,
      teamTasks: [],
      taskForm: { title: '', description: '', due_date: '' },
      isTeamModalOpen: false,
      isTasksLoading: false,
      isLoading: true,
      errorMessage: '',
      pendingCorrections: []
    }
  },
  computed: {
    todayLabel() {
      return new Intl.DateTimeFormat('fr-FR', {
        weekday: 'long', day: '2-digit', month: 'long', year: 'numeric'
      }).format(this.now)
    },
    currentTime() {
      return new Intl.DateTimeFormat('fr-FR', {
        hour: '2-digit', minute: '2-digit', second: '2-digit'
      }).format(this.now)
    },
    timeParts() { return this.currentTime.split(':') },
    teamSize()     { return this.employees.length },
    pendingCount() { return this.employees.filter(e => !e.validated).length },
    totalNights()  { return this.employees.reduce((t, e) => t + e.nights, 0) },
    missedCount()  { return this.employees.filter(e => e.missedClock).length },
    alerts()       { return this.employees.filter(e => e.nights > 3) },
    selectedCount(){ return this.selectedIds.length },
    maxHours()     { return Math.max(...this.employees.map(e => e.hours), 1) },
    allSelected()  { return this.employees.length > 0 && this.selectedIds.length === this.employees.length }
  },
  mounted() {
    this.loadTeam()
    this.timerId = window.setInterval(() => { this.now = new Date() }, 1000)
  },
  beforeUnmount() {
    window.clearInterval(this.timerId)
  },
  methods: {
    async loadTeam() {
      this.isLoading = true
      this.errorMessage = ''
      try {
        const [teamResponse, teamsResponse, usersResponse, correctionsResponse] = await Promise.all([
          api.getManagerTeam(), 
          api.getTeams(), 
          api.getUsers(),
          api.getPendingClockCorrections().catch(() => ({ data: { data: [] } }))
        ])
        this.employees = teamResponse.data?.data || []
        this.teams = teamsResponse.data?.data || []
        this.users = usersResponse.data?.data || []
        this.pendingCorrections = correctionsResponse.data?.data || []
      } catch (error) {
        this.errorMessage = error?.response?.data?.error || 'Impossible de charger les données de l’équipe.'
      } finally {
        this.isLoading = false
      }
    },
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
    async remind(employee) {
      try {
        await api.sendClockReminder(employee.id)
        await this.loadTeam()
      } catch (error) {
        this.errorMessage = 'La relance n’a pas pu être envoyée.'
      }
    },
    async removeMember(team, member) {
      if (!window.confirm(`Retirer ${member.username} de ${team.name} ?`)) return

      try {
        await api.removeTeamMember(team.id, member.id)
        await this.loadTeam()
      } catch (error) {
        this.errorMessage = 'Le membre n’a pas pu être retiré de l’équipe.'
      }
    },
    availableMembers(team) {
      const memberIds = new Set(team.members.map((member) => Number(member.id)))
      return this.users.filter((user) => user.role === 'employee' && !memberIds.has(Number(user.id)))
    },
    async addMember(team) {
      const userId = this.memberToAdd[team.id]
      if (!userId) return

      try {
        await api.addTeamMember(team.id, userId)
        this.memberToAdd[team.id] = ''
        await this.loadTeam()
      } catch (error) {
        this.errorMessage = 'Le membre n’a pas pu être ajouté à l’équipe.'
      }
    },
    async openTeam(team) {
      this.selectedTeam = team
      this.teamTasks = []
      this.taskForm = { title: '', description: '', due_date: '' }
      this.isTeamModalOpen = true
      this.isTasksLoading = true

      try {
        const response = await api.getTeamTasks(team.id)
        this.teamTasks = response.data?.data || []
      } catch (error) {
        this.errorMessage = 'Les tâches de cette équipe n’ont pas pu être chargées.'
      } finally {
        this.isTasksLoading = false
      }
    },
    closeTeam() {
      this.isTeamModalOpen = false
      this.selectedTeam = null
    },
    async createTask() {
      if (!this.selectedTeam || !this.taskForm.title.trim()) return

      try {
        const response = await api.createTeamTask(this.selectedTeam.id, {
          title: this.taskForm.title.trim(),
          description: this.taskForm.description.trim(),
          due_date: this.taskForm.due_date || null
        })
        this.teamTasks.unshift(response.data.data)
        this.taskForm = { title: '', description: '', due_date: '' }
      } catch (error) {
        this.errorMessage = 'La tâche n’a pas pu être créée.'
      }
    },
    async toggleTask(task) {
      if (!this.selectedTeam) return

      try {
        const status = task.status === 'completed' ? 'pending' : 'completed'
        const response = await api.updateTeamTaskStatus(this.selectedTeam.id, task.id, status)
        Object.assign(task, response.data.data)
      } catch (error) {
        this.errorMessage = 'Le statut de la tâche n’a pas pu être modifié.'
      }
    },
    async approveCorrection(id) {
      try {
        await api.approveClockCorrection(id)
        await this.loadTeam()
      } catch (error) {
        this.errorMessage = 'La correction n\'a pas pu être approuvée.'
      }
    },
    async rejectCorrection(id) {
      try {
        await api.rejectClockCorrection(id)
        await this.loadTeam()
      } catch (error) {
        this.errorMessage = 'La correction n\'a pas pu être rejetée.'
      }
    },
    async clockTeam(team) {
      if (!window.confirm(`Pointer toute l'équipe "${team.name}" ?`)) return
      try {
        const res = await api.clockTeam(team.id)
        const results = res.data?.data || []
        const errors = results.filter(r => r.error)
        if (errors.length) {
          this.errorMessage = `${errors.length} pointage(s) ont échoué.`
        }
        await this.loadTeam()
      } catch (error) {
        this.errorMessage = 'Le pointage d\'équipe a échoué.'
      }
    }
  }
}
</script>

<template>
  <section class="dashboard-page">
    <div class="welcome-row">
      <div>
        <p class="dashboard-kicker">TABLEAU DE BORD MANAGER</p>
        <h1>Bonjour, {{ currentUserName }}</h1>
        <p class="dashboard-date">{{ todayLabel }}</p>
      </div>
      <div class="clock-box">
        <span class="clock-label">Heure locale</span>
        <div class="flip-clock" aria-label="Heure actuelle">
          <template v-for="(part, partIndex) in timeParts" :key="partIndex">
            <div class="flip-group">
              <span v-for="(digit, digitIndex) in part.split('')" :key="`${partIndex}-${digitIndex}-${digit}`" class="flip-digit">{{ digit }}</span>
            </div>
            <span v-if="partIndex < 2" class="flip-separator">:</span>
          </template>
        </div>
      </div>
    </div>

    <p v-if="isLoading" class="demo-notice" role="status">Synchronisation des données de l’équipe…</p>
    <p v-else-if="errorMessage" class="demo-notice" role="alert"><strong>Erreur.</strong> {{ errorMessage }} <button class="link-btn" type="button" @click="loadTeam">Réessayer</button></p>
    <p v-else-if="!employees.length" class="demo-notice" role="status">Aucun collaborateur à afficher pour le moment.</p>

    <section class="teams-section" aria-labelledby="managed-teams-title">
      <div class="section-title">
        <div>
          <p class="card-kicker">MES ÉQUIPES</p>
          <h2 id="managed-teams-title">Équipes et membres</h2>
        </div>
        <span class="team-count">{{ teams.length }} équipe{{ teams.length > 1 ? 's' : '' }}</span>
      </div>
      <div v-if="teams.length" class="teams-grid">
        <article v-for="team in teams" :key="team.id" class="team-card">
          <div class="team-card-heading"><div><h3>{{ team.name }}</h3><span>{{ team.members.length }} membre{{ team.members.length > 1 ? 's' : '' }}</span></div><div style="display:flex;gap:6px;align-items:center;"><button class="team-clock-btn" type="button" @click="clockTeam(team)">🦇 Pointer</button><button class="team-id team-open" type="button" @click="openTeam(team)">Voir ↗</button></div></div>
          <ul v-if="team.members.length" class="member-list"><li v-for="member in team.members" :key="member.id"><span class="member-avatar">{{ member.username.slice(0, 1).toUpperCase() }}</span><span><b>{{ member.username }}</b><small>{{ member.email }}</small></span><i :class="{ inactive: !member.active }">{{ member.active ? 'Actif' : 'Inactif' }}</i><button class="remove-member" type="button" @click="removeMember(team, member)">Retirer</button></li></ul>
          <p v-else class="empty-members">Aucun membre affecté.</p>
          <form class="add-member-form" @submit.prevent="addMember(team)"><select v-model="memberToAdd[team.id]" aria-label="Choisir un employé" :disabled="!availableMembers(team).length"><option value="">{{ availableMembers(team).length ? 'Ajouter un employé…' : 'Tous les employés sont déjà affectés' }}</option><option v-for="user in availableMembers(team)" :key="user.id" :value="user.id">{{ user.username }} · {{ user.email }}</option></select><button type="submit" :disabled="!availableMembers(team).length">Ajouter</button></form>
        </article>
      </div>
      <p v-else class="empty-teams">Aucune équipe ne vous est encore attribuée. L’administrateur peut en créer une et vous désigner comme manager.</p>
    </section>

    <div v-if="isTeamModalOpen && selectedTeam" class="team-modal-backdrop" role="presentation" @click.self="closeTeam">
      <section class="team-modal" role="dialog" aria-modal="true" aria-labelledby="team-modal-title">
        <button class="modal-close" type="button" aria-label="Fermer" @click="closeTeam">×</button>
        <p class="card-kicker">DÉTAIL DE L’ÉQUIPE</p>
        <h2 id="team-modal-title">{{ selectedTeam.name }}</h2>
        <p class="team-description">{{ selectedTeam.description || 'Aucune description n’a encore été ajoutée à cette équipe.' }}</p>
        <div class="modal-members"><span class="modal-label">MEMBRES · {{ selectedTeam.members.length }}</span><div class="member-pills"><span v-for="member in selectedTeam.members" :key="member.id">{{ member.username }}</span><span v-if="!selectedTeam.members.length" class="muted-pill">Aucun membre</span></div></div>
        <div class="tasks-heading"><div><span class="modal-label">TÂCHES DE L’ÉQUIPE</span><h3>À faire ensemble</h3></div><span>{{ teamTasks.filter((task) => task.status === 'completed').length }}/{{ teamTasks.length }} terminées</span></div>
        <form class="task-form" @submit.prevent="createTask"><input v-model="taskForm.title" required type="text" placeholder="Titre de la tâche"><textarea v-model="taskForm.description" rows="2" placeholder="Description (facultative)"></textarea><div class="task-form-bottom"><input v-model="taskForm.due_date" type="date" aria-label="Échéance"><button type="submit">Créer la tâche</button></div></form>
        <div v-if="isTasksLoading" class="tasks-state">Chargement des tâches…</div>
        <div v-else-if="teamTasks.length" class="tasks-list"><article v-for="task in teamTasks" :key="task.id" class="task-item" :class="{ completed: task.status === 'completed' }"><button class="task-check" type="button" :aria-label="task.status === 'completed' ? 'Marquer non terminée' : 'Marquer terminée'" @click="toggleTask(task)">{{ task.status === 'completed' ? '✓' : '' }}</button><div><strong>{{ task.title }}</strong><p v-if="task.description">{{ task.description }}</p><small v-if="task.due_date">Échéance : {{ task.due_date }}</small></div></article></div>
        <div v-else class="tasks-state">Aucune tâche pour cette équipe. Crée la première ci-dessus.</div>
      </section>
    </div>

    <!-- Alertes automatiques : nuits > 3 -->
    <div v-if="alerts.length" class="alert-banner" role="alert">
      <span class="alert-mark" aria-hidden="true"></span>
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
        <p>Membres de l'équipe</p>
        <strong>{{ teamSize }}</strong>
      </article>
      <article class="stat-card amber">
        <p>Timesheets en attente</p>
        <strong>{{ pendingCount }}</strong>
      </article>
      <article class="stat-card violet">
        <p>Nuits travaillées (semaine)</p>
        <strong>{{ totalNights }}</strong>
      </article>
      <article class="stat-card red">
        <p>Oublis de pointage</p>
        <strong>{{ missedCount }}</strong>
      </article>
    </div>

    <!-- Corrections en attente -->
    <section v-if="pendingCorrections.length" class="team-section">
      <div class="section-title">
        <div>
          <p class="card-kicker">CORRECTIONS</p>
          <h2>Demandes d'oubli de pointage ({{ pendingCorrections.length }})</h2>
        </div>
      </div>
      <div class="table-wrap">
        <div class="team-table head" style="grid-template-columns: 1fr 1fr 1fr 2fr 1fr;">
          <span>Employé</span>
          <span>Date et heure proposée</span>
          <span>Type</span>
          <span>Raison</span>
          <span>Actions</span>
        </div>
        <div v-for="corr in pendingCorrections" :key="corr.id" class="team-table" style="grid-template-columns: 1fr 1fr 1fr 2fr 1fr;">
          <span class="cell-name">
            <b>Utilisateur #{{ corr.user_id }}</b>
          </span>
          <span>{{ new Intl.DateTimeFormat('fr-FR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(corr.proposed_time)) }}</span>
          <span>
            <b class="badge-nights" :class="{ danger: !corr.proposed_status }">
              {{ corr.proposed_status ? 'Clock In' : 'Clock Out' }}
            </b>
          </span>
          <span>{{ corr.reason }}</span>
          <span class="cell-actions">
            <button type="button" class="link-btn" @click="approveCorrection(corr.id)">Approuver</button>
            <button type="button" class="link-btn danger" @click="rejectCorrection(corr.id)">Rejeter</button>
          </span>
        </div>
      </div>
    </section>

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
            <b v-if="emp.missedClock" class="badge-missed">
              <i></i>Oubli de pointage
            </b>
          </span>
          <span><b>{{ emp.hours.toFixed(1) }} h</b></span>
          <span>
            <b class="badge-nights" :class="{ danger: emp.nights > 3 }" :aria-label="`${emp.nights} nuit${emp.nights > 1 ? 's' : ''} travaillée${emp.nights > 1 ? 's' : ''}`">
              {{ emp.nights }}
            </b>
          </span>
          <span>
            <b class="row-status" :class="{ pending: !emp.validated }">
              <i></i>{{ emp.validated ? 'Validé' : 'En attente' }}
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
.demo-notice { margin: -8px 0 20px; padding: 11px 14px; color: #6f5a1b; font-size: 12px; background: #fff8df; border-left: 3px solid #f0ad32; }
.welcome-row, .section-title { display: flex; align-items: flex-start; justify-content: space-between; gap: 18px; }
.welcome-row { align-items: flex-end; margin-bottom: 24px; }
.dashboard-kicker, .card-kicker { margin: 0 0 8px; color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; }
.welcome-row h1 { margin: 0; font: 800 clamp(25px, 4vw, 34px) 'Manrope', sans-serif; letter-spacing: -.055em; }
.dashboard-date { margin: 8px 0 0; color: #8c96a5; font-size: 13px; text-transform: capitalize; }

/* Horloge */
.clock-box { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; }
.clock-label { color: #a0a8b4; font-size: 10px; font-weight: 700; letter-spacing: .1em; text-transform: uppercase; }
.flip-clock { display: flex; align-items: center; justify-content: flex-end; gap: 5px; }
.flip-group { display: flex; gap: 3px; }
.flip-digit { display: grid; width: 28px; height: 38px; place-items: center; color: #fff; font: 800 20px 'Manrope', sans-serif; background: #1e2530; border-radius: 6px; }
.flip-separator { color: #8f98a6; font-size: 20px; font-weight: 700; }

/* Alertes */
.alert-banner { display: flex; gap: 14px; align-items: flex-start; margin-bottom: 20px; padding: 16px 18px; background: #fff5f0; border-left: 4px solid #e85d65; border-radius: 10px; color: #7a3b40; }
.alert-mark { flex: 0 0 auto; width: 22px; height: 22px; margin-top: 2px; border: 2px solid #e85d65; border-radius: 50%; position: relative; }
.alert-mark::before { content: ''; position: absolute; top: 4px; left: 50%; width: 2px; height: 8px; background: #e85d65; transform: translateX(-50%); border-radius: 1px; }
.alert-mark::after { content: ''; position: absolute; bottom: 3px; left: 50%; width: 3px; height: 3px; background: #e85d65; border-radius: 50%; transform: translateX(-50%); }
.alert-banner strong { display: block; color: #b6444d; font-size: 13px; margin-bottom: 6px; }
.alert-banner ul { margin: 0; padding-left: 18px; font-size: 12px; }
.alert-banner b { color: #b6444d; }

/* Stats */
.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 20px; }
.stat-card { position: relative; padding: 18px; background: #fff; border: 1px solid #eaedf2; border-radius: 12px; overflow: hidden; box-shadow: 0 8px 25px #29375608; }
.stat-card p { margin: 0 0 12px; color: #8c96a5; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; }
.stat-card strong { color: #293140; font: 800 28px 'Manrope', sans-serif; letter-spacing: -.04em; }
.stat-card::before { content: ''; position: absolute; inset: 0 0 auto; height: 3px; }
.stat-card.blue::before   { background: #5796e7; }
.stat-card.amber::before  { background: #f0ad32; }
.stat-card.violet::before { background: #8b7ded; }
.stat-card.red::before    { background: #e85d65; }

/* Sections */
.team-section, .chart-section { margin-top: 18px; padding: 24px; background: #fff; border: 1px solid #eaedf2; border-radius: 12px; box-shadow: 0 8px 25px #29375608; }
.teams-section { margin-top: 18px; padding: 24px; background: #fff; border: 1px solid #eaedf2; border-radius: 12px; box-shadow: 0 8px 25px #29375608; }.team-count, .team-id { color: #8c96a5; font-size: 11px; }.teams-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; margin-top: 18px; }.team-card { padding: 16px; background: #f8f9fc; border: 1px solid #edf0f4; border-radius: 10px; }.team-card-heading { display: flex; justify-content: space-between; gap: 12px; }.team-card h3 { margin: 0; color: #293140; font: 700 16px 'Manrope', sans-serif; }.team-card-heading span { display: block; margin-top: 5px; color: #8c96a5; font-size: 11px; }.member-list { display: grid; gap: 9px; margin: 16px 0 0; padding: 0; list-style: none; }.member-list li { display: flex; align-items: center; gap: 9px; padding-top: 9px; border-top: 1px solid #e9edf3; }.member-avatar { display: grid; width: 28px; height: 28px; place-items: center; color: #655bd0; font-size: 11px; font-weight: 800; background: #e9e7ff; border-radius: 50%; }.member-list li > span:nth-child(2) { display: grid; flex: 1; gap: 2px; }.member-list b { color: #303847; font-size: 12px; }.member-list small { color: #8c96a5; font-size: 10px; }.member-list i { color: #43ae76; font-size: 10px; font-style: normal; font-weight: 700; }.member-list i.inactive { color: #e85d65; }.remove-member { padding: 3px 0; color: #e85d65; font-size: 10px; font-weight: 700; background: transparent; border: 0; cursor: pointer; }.remove-member:hover { text-decoration: underline; }.add-member-form { display: flex; gap: 8px; margin-top: 14px; }.add-member-form select { min-width: 0; flex: 1; padding: 7px; color: #5d6675; font-size: 11px; background: #fff; border: 1px solid #e7eaf0; border-radius: 6px; }.add-member-form select:disabled { color: #9aa3af; background: #f1f3f6; }.add-member-form button { padding: 7px 10px; color: #fff; font-size: 11px; font-weight: 700; background: #786be7; border: 0; border-radius: 6px; cursor: pointer; }.add-member-form button:disabled { cursor: not-allowed; opacity: .45; }.empty-members, .empty-teams { color: #8c96a5; font-size: 12px; }.empty-members { margin: 16px 0 0; }.empty-teams { margin: 18px 0 0; }
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
.badge-missed { display: inline-flex; align-items: center; gap: 5px; margin-top: 2px; padding: 2px 8px; color: #b6444d; font-size: 9px; font-weight: 700; background: #fff0f1; border-radius: 99px; width: fit-content; }
.badge-missed i { width: 6px; height: 6px; background: #e85d65; border-radius: 50%; }
.badge-nights { display: inline-block; padding: 3px 9px; color: #4b3fc4; background: #ece9ff; border-radius: 99px; font-size: 11px; font-weight: 700; }
.badge-nights.danger { color: #b6444d; background: #fff0f1; }
.row-status { display: inline-flex; align-items: center; gap: 6px; font-size: 11px; color: #43ae76; }
.row-status i { width: 7px; height: 7px; background: currentColor; border-radius: 50%; }
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
  .clock-box { align-items: flex-start; margin-top: 14px; }
  .flip-clock { justify-content: flex-start; }
  .section-title { flex-direction: column; align-items: stretch; }
  .bar-row { grid-template-columns: 110px 1fr; }
  .teams-grid { grid-template-columns: 1fr; }
}
@media (max-width: 450px) {
  .stats-grid { grid-template-columns: 1fr; }
  .team-section, .chart-section { padding: 17px; }
  .flip-digit { width: 24px; height: 34px; font-size: 18px; }
  .bar-row { grid-template-columns: 90px 1fr; }
}
.team-clock-btn { padding: 4px 10px; color: #fff; font-size: 10px; font-weight: 700; background: #786be7; border: 0; border-radius: 99px; cursor: pointer; transition: background .15s; }.team-clock-btn:hover { background: #5f54c8; }.team-open { padding: 0; color: #786be7; background: transparent; border: 0; cursor: pointer; }.team-open:hover { text-decoration: underline; }.team-modal-backdrop { position: fixed; z-index: 60; inset: 0; display: grid; place-items: center; padding: 20px; background: rgba(20, 25, 35, .65); }.team-modal { position: relative; width: min(100%, 650px); max-height: min(88vh, 760px); overflow-y: auto; padding: 30px; background: #fff; border-radius: 16px; box-shadow: 0 24px 80px rgba(0, 0, 0, .22); }.modal-close { position: absolute; top: 12px; right: 14px; width: 34px; height: 34px; color: #7d8796; background: transparent; border: 0; font-size: 25px; cursor: pointer; }.team-modal h2 { margin: 0; color: #293140; font: 800 30px 'Manrope', sans-serif; letter-spacing: -.06em; }.team-description { margin: 8px 0 20px; color: #7d8796; font-size: 13px; line-height: 1.55; }.modal-label { color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; }.member-pills { display: flex; flex-wrap: wrap; gap: 7px; margin-top: 9px; }.member-pills span { padding: 6px 10px; color: #5148a7; font-size: 11px; font-weight: 700; background: #eeedff; border-radius: 99px; }.member-pills .muted-pill { color: #8c96a5; background: #f1f3f6; }.tasks-heading { display: flex; align-items: end; justify-content: space-between; gap: 12px; margin-top: 26px; padding-top: 20px; border-top: 1px solid #edf0f4; }.tasks-heading h3 { margin: 4px 0 0; color: #293140; font: 700 18px 'Manrope', sans-serif; }.tasks-heading > span { color: #43ae76; font-size: 11px; font-weight: 700; }.task-form { display: grid; gap: 8px; margin-top: 14px; padding: 13px; background: #f8f9fc; border: 1px solid #edf0f4; border-radius: 10px; }.task-form input, .task-form textarea { width: 100%; padding: 9px 10px; color: #303847; background: #fff; border: 1px solid #e4e8ef; border-radius: 6px; font-size: 12px; resize: vertical; }.task-form-bottom { display: flex; gap: 8px; }.task-form-bottom input { flex: 1; }.task-form button { padding: 8px 12px; color: #fff; background: #786be7; border: 0; border-radius: 6px; font-size: 11px; font-weight: 700; cursor: pointer; }.tasks-list { display: grid; gap: 8px; margin-top: 14px; }.task-item { display: flex; align-items: flex-start; gap: 10px; padding: 12px; border: 1px solid #edf0f4; border-radius: 9px; }.task-item.completed { background: #f3fbf6; border-color: #d7efdf; }.task-check { display: grid; width: 22px; height: 22px; flex: 0 0 auto; place-items: center; color: #fff; background: #fff; border: 2px solid #b8c0cc; border-radius: 6px; cursor: pointer; }.task-item.completed .task-check { background: #43ae76; border-color: #43ae76; }.task-item > div { min-width: 0; }.task-item strong { color: #303847; font-size: 13px; }.task-item.completed strong { color: #71917b; text-decoration: line-through; }.task-item p { margin: 4px 0 0; color: #7d8796; font-size: 11px; line-height: 1.4; }.task-item small { display: block; margin-top: 6px; color: #9aa3af; font-size: 10px; }.tasks-state { margin-top: 15px; padding: 18px; color: #8c96a5; font-size: 12px; text-align: center; background: #f8f9fc; border-radius: 8px; }
</style>

