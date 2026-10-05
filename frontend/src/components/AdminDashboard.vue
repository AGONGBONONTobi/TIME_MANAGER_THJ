<script>
import api from '../services/api'

export default {
  name: 'AdminDashboard',
  data() {
    return {
      managers: [],
      teams: [],
      users: [],
      leaveRequests: [],
      payrollRules: [],
      fatigueAlerts: [],
      isLoading: true,
      errorMessage: '',
      newTeamName: '',
      newTeamManagerId: ''
    }
  },
  methods: {
    async loadData() {
      this.isLoading = true
      this.errorMessage = ''

      try {
        const [usersResponse, leaveResponse, payrollResponse, teamResponse, teamsResponse] = await Promise.all([
          api.getUsers(),
          api.getLeaveRequests(),
          api.getPayrollRules(),
          api.getManagerTeam(),
          api.getTeams()
        ])
        this.users = usersResponse.data.data || []
        const userNames = new Map(this.users.map((user) => [Number(user.id), user.username]))
        this.managers = this.users.filter((user) => user.role === 'manager').map((manager) => ({ ...manager, name: manager.username, scope: 'Accès manager', active: true }))
        this.leaveRequests = (leaveResponse.data.data || []).map((request) => ({ ...request, name: userNames.get(Number(request.user_id)) || `Utilisateur #${request.user_id}` }))
        this.payrollRules = (payrollResponse.data.data || []).map((rule) => ({ ...rule, label: rule.name, value: `${rule.rule_type} · ${rule.value}`, tone: 'violet' }))
        this.fatigueAlerts = (teamResponse.data.data || []).filter((employee) => employee.nights >= 3 || employee.missedClock).map((employee) => ({ name: employee.name, detail: employee.missedClock ? 'Pointage incomplet cette semaine' : `${employee.nights} nuits cette semaine` }))
        this.teams = teamsResponse.data.data || []
      } catch (error) {
        this.errorMessage = 'Impossible de charger les données administratives.'
      } finally {
        this.isLoading = false
      }
    },
    async reviewLeave(request, status) {
      try {
        if (status === 'approved') await api.approveLeaveRequest(request.id)
        else await api.rejectLeaveRequest(request.id)
        await this.loadData()
      } catch (error) {
        this.errorMessage = 'La demande n’a pas pu être mise à jour.'
      }
    },
    async createTeam() {
      if (!this.newTeamName.trim() || !this.newTeamManagerId) return

      try {
        await api.createTeam({ name: this.newTeamName.trim(), manager_id: Number(this.newTeamManagerId) })
        this.newTeamName = ''
        this.newTeamManagerId = ''
        await this.loadData()
      } catch (error) {
        this.errorMessage = 'L’équipe n’a pas pu être créée.'
      }
    }
  },
  mounted() { this.loadData() }
}
</script>

<template>
  <section class="admin-page">
    <header class="admin-header">
      <div>
        <p class="eyebrow">ADMINISTRATION · RH · COMPTABILITÉ</p>
        <h1>Gouverner le temps.</h1>
        <p>Le troisième parcours rassemble les règles, les absences et les accès depuis les données persistées de l’organisation.</p>
      </div>
      <router-link class="back-link" :to="{ name: 'user' }">Retour à l’espace utilisateur</router-link>
    </header>

    <p v-if="isLoading" class="demo-notice" role="status">Chargement des données administratives…</p>
    <p v-else-if="errorMessage" class="demo-notice" role="alert">{{ errorMessage }} <button class="action-link" type="button" @click="loadData">Réessayer</button></p>

    <div class="admin-grid">
        <section class="admin-card team-management-card">
          <div class="card-heading"><div><p class="card-kicker">ORGANISATION</p><h2>Créer une équipe</h2></div><span class="card-count">{{ teams.length }} équipes</span></div>
          <form class="team-form" @submit.prevent="createTeam"><input v-model="newTeamName" required type="text" placeholder="Nom de l’équipe"><select v-model="newTeamManagerId" required><option disabled value="">Choisir un manager</option><option v-for="manager in managers" :key="manager.id" :value="manager.id">{{ manager.name }}</option></select><button class="action-link" type="submit">Créer</button></form>
          <ul class="admin-list compact-list"><li v-for="team in teams" :key="team.id"><div><strong>{{ team.name }}</strong><span>{{ team.members.length }} membre{{ team.members.length > 1 ? 's' : '' }}</span></div><span class="card-count">Manager #{{ team.manager_id }}</span></li></ul>
        </section>
      <section class="admin-card access-card">
        <div class="card-heading"><div><p class="card-kicker">ACCÈS</p><h2>Droits des managers</h2></div><span class="card-count">{{ managers.length }} actifs</span></div>
        <ul class="admin-list">
          <li v-for="manager in managers" :key="manager.id">
            <div><strong>{{ manager.name }}</strong><span>{{ manager.scope }}</span></div>
            <span class="card-count">Actif</span>
          </li>
        </ul>
      </section>

      <section class="admin-card leave-card">
        <div class="card-heading"><div><p class="card-kicker">ABSENCES</p><h2>Demandes RH</h2></div><span class="card-count">{{ leaveRequests.length }} à traiter</span></div>
        <ul class="admin-list">
          <li v-for="request in leaveRequests" :key="request.id">
            <div><strong>{{ request.name }} · {{ request.type }}</strong><span>{{ request.start_date }} → {{ request.end_date }}</span></div>
            <div class="leave-actions"><button v-if="request.status === 'pending'" class="action-link" type="button" @click="reviewLeave(request, 'approved')">Approuver</button><button v-if="request.status === 'pending'" class="action-link" type="button" @click="reviewLeave(request, 'rejected')">Refuser</button><span v-else class="card-count">{{ request.status }}</span></div>
          </li>
        </ul>
      </section>
    </div>

    <section class="admin-card payroll-card">
      <div class="card-heading"><div><p class="card-kicker">PAIE</p><h2>Règles de majoration</h2></div><span class="card-count">{{ payrollRules.length }} règles</span></div>
      <div class="rules-grid"><article v-for="rule in payrollRules" :key="rule.label" class="rule-card" :class="rule.tone"><span>{{ rule.label }}</span><strong>{{ rule.value }}</strong></article></div>
    </section>

    <section class="admin-card fatigue-card">
      <div class="card-heading"><div><p class="card-kicker">PRÉVENTION</p><h2>Vigilance fatigue</h2></div><span class="card-count">{{ fatigueAlerts.length }} alertes</span></div>
      <ul class="fatigue-list"><li v-for="alert in fatigueAlerts" :key="alert.name"><span class="alert-dot" aria-hidden="true"></span><div><strong>{{ alert.name }}</strong><span>{{ alert.detail }}</span></div></li></ul>
    </section>
  </section>
</template>

<style scoped>
.admin-page { --ink: #252522; --muted: #716b64; --line: rgba(37, 33, 27, .14); --copper: #a7673c; width: min(100%, 1120px); margin: 0 auto; color: var(--ink); }.admin-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 2rem; padding-bottom: 1.5rem; margin-bottom: 1.5rem; border-bottom: 1px solid var(--line); }.eyebrow, .card-kicker { margin: 0 0 8px; color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; }.admin-header h1 { margin: 0; font: 800 clamp(25px, 3.5vw, 34px) 'Manrope', sans-serif; letter-spacing: -.055em; line-height: 1.1; }.admin-header p:not(.eyebrow) { max-width: 580px; margin: 8px 0 0; color: var(--muted); font-size: 13px; line-height: 1.6; }.back-link { color: var(--ink); font-size: .75rem; font-weight: 800; white-space: nowrap; flex-shrink: 0; }.demo-notice { margin: 1.5rem 0 0; padding: 12px 14px; color: #6f5a1b; font-size: .8rem; background: #fff8df; border-left: 3px solid #f0ad32; }.admin-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; margin-top: 18px; }.admin-card { padding: 1.35rem; background: #fff; border: 1px solid var(--line); box-shadow: 0 12px 30px rgba(37, 33, 27, .05); }.card-heading { display: flex; align-items: start; justify-content: space-between; gap: 1rem; }.card-kicker { margin-bottom: .4rem; }.card-heading h2 { margin: 0; font-size: 1.15rem; letter-spacing: -.04em; }.card-count { color: var(--muted); font-size: .7rem; white-space: nowrap; }.admin-list, .fatigue-list { display: grid; gap: 0; margin: 1.2rem 0 0; padding: 0; list-style: none; }.admin-list li, .fatigue-list li { display: flex; align-items: center; justify-content: space-between; gap: 1rem; padding: .85rem 0; border-top: 1px solid var(--line); }.admin-list strong, .admin-list span, .fatigue-list strong, .fatigue-list span { display: block; }.admin-list strong, .fatigue-list strong { font-size: .8rem; }.admin-list span, .fatigue-list span { margin-top: .25rem; color: var(--muted); font-size: .72rem; }.action-link { color: var(--copper); background: transparent; border: 0; font-size: .72rem; font-weight: 800; cursor: pointer; }.action-link:disabled { color: #9a958e; cursor: default; }.payroll-card, .fatigue-card { margin-top: 18px; }.rules-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-top: 1.2rem; }.rule-card { padding: 1rem; border-top: 3px solid; }.rule-card span, .rule-card strong { display: block; }.rule-card span { color: var(--muted); font-size: .72rem; }.rule-card strong { margin-top: .7rem; font-size: 1.55rem; }.rule-card.violet { color: #6658ce; background: #f3f1ff; border-color: #887ce8; }.rule-card.amber { color: #8e6818; background: #fff8df; border-color: #f0ad32; }.rule-card.blue { color: #3f71af; background: #eff6ff; border-color: #5796e7; }.alert-dot { width: 9px; height: 9px; flex: 0 0 auto; margin-right: .2rem; background: #e85d65; border-radius: 50%; box-shadow: 0 0 0 5px #fff0f1; }.fatigue-list li { justify-content: start; }
@media (max-width: 760px) { .admin-page { width: min(100% - 1rem, 1120px); margin-top: 2.5rem; }.admin-header { display: block; }.back-link { display: inline-block; margin-top: 1.5rem; }.admin-grid, .rules-grid { grid-template-columns: 1fr; } }
.team-form { display: grid; grid-template-columns: 1.2fr 1fr auto; gap: .6rem; margin-top: 1rem; }.team-form input, .team-form select { min-height: 40px; padding: .55rem .65rem; color: var(--ink); background: #fff; border: 1px solid var(--line); border-radius: 0; }.team-form .action-link { padding: .55rem .8rem; border: 1px solid var(--line); cursor: pointer; }.compact-list { margin-top: .8rem; }
</style>
