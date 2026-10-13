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
      isPayrollRuleModalOpen: false,
      editingPayrollRuleId: null,
      payrollRuleForm: { name: '', rule_type: 'night', value: '', active: true },
      fatigueAlerts: [],
      isLoading: true,
      errorMessage: '',
      newTeamName: '',
      newTeamManagerId: '',
      // Filtres
      searchQuery: '',
      roleFilter: '',
      statusFilter: '',
      currentPage: 1,
      perPage: 10,
      isUserModalOpen: false,
      temporaryCredentials: null,
      copiedTemporaryPassword: false,
      teamFilter: '',
      sortBy: 'username',
      newUser: { username: '', email: '', role: 'employee', status: 'active', contract_start: '', contract_end: '' }
    }
  },
  computed: {
    // Stats
    stats() {
      return {
        total: this.users.length,
        admins: this.users.filter(u => u.role === 'admin').length,
        managers: this.users.filter(u => u.role === 'manager').length,
        employees: this.users.filter(u => u.role === 'employee').length,
        active: this.users.filter(u => u.status === 'active' || !u.status).length
      }
    },
    // Filtrage
    filteredUsers() {
      let result = this.users

      // Recherche
      if (this.searchQuery.trim()) {
        const q = this.searchQuery.toLowerCase()
        result = result.filter(u =>
          u.username?.toLowerCase().includes(q) ||
          u.email?.toLowerCase().includes(q)
        )
      }

      // Filtre rôle
      if (this.roleFilter) {
        result = result.filter(u => u.role === this.roleFilter)
      }

      // Filtre statut
      if (this.statusFilter) {
        result = result.filter(u => (u.status || 'active') === this.statusFilter)
      }

      if (this.teamFilter) {
        const team = this.teams.find((item) => String(item.id) === String(this.teamFilter))
        const memberIds = new Set((team?.members || []).map((member) => String(member.id || member.user_id)))
        result = result.filter((user) => memberIds.has(String(user.id)))
      }

      return [...result].sort((a, b) => {
        if (this.sortBy === 'contract_start') return String(a.contract_start || '').localeCompare(String(b.contract_start || ''))
        return String(a.username || '').localeCompare(String(b.username || ''), 'fr')
      })
    },
    // Pagination
    totalPages() {
      return Math.max(1, Math.ceil(this.filteredUsers.length / this.perPage))
    },
    paginatedUsers() {
      const start = (this.currentPage - 1) * this.perPage
      return this.filteredUsers.slice(start, start + this.perPage)
    },
    paginationRange() {
      const start = (this.currentPage - 1) * this.perPage + 1
      const end = Math.min(this.currentPage * this.perPage, this.filteredUsers.length)
      return { start, end }
    }
  },
  methods: {
    openUserModal() { this.isUserModalOpen = true },
    async createAdminUser() {
      this.errorMessage = ''
      try {
        const response = await api.createUser(this.newUser)
        const { data: user, temporary_password: temporaryPassword } = response.data || {}
        if (!user || !temporaryPassword) {
          throw new Error('Réponse de création incomplète.')
        }
        this.users.push(user)
        this.temporaryCredentials = { username: user.username, email: user.email, password: temporaryPassword }
        this.copiedTemporaryPassword = false
        this.isUserModalOpen = false
        this.newUser = { username: '', email: '', role: 'employee', status: 'active', contract_start: '', contract_end: '' }
      } catch (error) {
        this.errorMessage = error.response?.data?.error || error.message || 'La création de l’utilisateur a échoué.'
      }
    },
    async copyTemporaryPassword() {
      try {
        await navigator.clipboard.writeText(this.temporaryCredentials.password)
        this.copiedTemporaryPassword = true
      } catch {
        this.errorMessage = 'La copie automatique a échoué. Sélectionnez et copiez le mot de passe affiché.'
      }
    },
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
    },
    async deleteTeam(teamId) {
      if (!window.confirm('Confirmer la suppression de cette équipe ?')) return
      try {
        await api.deleteTeam(teamId)
        await this.loadData()
      } catch (error) {
        this.errorMessage = 'Impossible de supprimer cette équipe.'
      }
    },
    async changeRole(userId, newRole) {
      if (!window.confirm(`Confirmer le changement de rôle vers ${newRole} ?`)) return
      try {
        await api.updateUserRole(userId, newRole)
        await this.loadData()
      } catch (error) {
        this.errorMessage = 'Le rôle n’a pas pu être mis à jour.'
      }
    },
    async updateUserLifecycle(user) {
      try {
        await api.updateUser(user.id, {
          status: user.status,
          contract_start: user.contract_start || null,
          contract_end: user.contract_end || null
        })
        this.errorMessage = ''
        alert(`Les informations de ${user.username} ont été mises à jour.`)
      } catch (error) {
        this.errorMessage = 'Impossible de mettre à jour les informations de cet employé.'
      }
    },
    openPayrollRuleModal(rule = null) {
      this.editingPayrollRuleId = rule?.id || null
      this.payrollRuleForm = rule
        ? { name: rule.name, rule_type: rule.rule_type, value: rule.value, active: rule.active }
        : { name: '', rule_type: 'night', value: '', active: true }
      this.isPayrollRuleModalOpen = true
    },
    closePayrollRuleModal() {
      this.isPayrollRuleModalOpen = false
      this.editingPayrollRuleId = null
    },
    async savePayrollRule() {
      if (!this.payrollRuleForm.name.trim() || this.payrollRuleForm.value === '') return
      try {
        const payload = {
          name: this.payrollRuleForm.name.trim(),
          rule_type: this.payrollRuleForm.rule_type,
          value: Number(this.payrollRuleForm.value),
          active: Boolean(this.payrollRuleForm.active)
        }
        if (this.editingPayrollRuleId) await api.updatePayrollRule(this.editingPayrollRuleId, payload)
        else await api.createPayrollRule(payload)
        this.closePayrollRuleModal()
        await this.loadData()
      } catch (error) {
        this.errorMessage = 'La règle de paie n’a pas pu être enregistrée.'
      }
    },
    async deletePayrollRule(rule) {
      if (!window.confirm(`Supprimer la règle « ${rule.name} » ?`)) return
      try {
        await api.deletePayrollRule(rule.id)
        await this.loadData()
      } catch (error) {
        this.errorMessage = 'La règle de paie n’a pas pu être supprimée.'
      }
    },
    // Helpers UI
    roleBadgeClass(role) {
      return {
        'admin': 'badge-admin',
        'manager': 'badge-manager',
        'employee': 'badge-employee'
      }[role] || 'badge-employee'
    },
    roleLabel(role) {
      return { 'admin': 'Admin', 'manager': 'Manager', 'employee': 'Employé' }[role] || role
    },
    statusLabel(status) {
      return { 'active': 'Actif', 'suspended': 'Suspendu', 'terminated': 'Terminé' }[status || 'active'] || 'Actif'
    },
    statusBadgeClass(status) {
      return {
        'active': 'status-active',
        'suspended': 'status-suspended',
        'terminated': 'status-terminated'
      }[status || 'active'] || 'status-active'
    },
    initials(name) {
      if (!name) return '?'
      return name.split(/[\s_.-]+/).map(p => p[0]?.toUpperCase() || '').slice(0, 2).join('')
    },
    goToPage(page) {
      if (page >= 1 && page <= this.totalPages) {
        this.currentPage = page
      }
    },
    resetFilters() {
      this.searchQuery = ''
      this.roleFilter = ''
      this.statusFilter = ''
      this.teamFilter = ''
      this.sortBy = 'username'
      this.currentPage = 1
    }
  },
  watch: {
    searchQuery() { this.currentPage = 1 },
    roleFilter() { this.currentPage = 1 },
    statusFilter() { this.currentPage = 1 }
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
        <p>Gérez les utilisateurs, les rôles, les équipes et les règles RH depuis une interface unique.</p>
      </div>
      <router-link class="back-link" :to="{ name: 'user' }">← Retour</router-link>
    </header>

    <p v-if="isLoading" class="demo-notice" role="status">Chargement des données administratives…</p>
    <p v-else-if="errorMessage" class="demo-notice" role="alert">{{ errorMessage }} <button class="action-link" type="button" @click="loadData">Réessayer</button></p>

    <!-- Stats -->
    <div class="stats-grid">
      <article class="stat-card blue">
        <p>Total utilisateurs</p>
        <strong>{{ stats.total }}</strong>
      </article>
      <article class="stat-card violet">
        <p>Admins</p>
        <strong>{{ stats.admins }}</strong>
      </article>
      <article class="stat-card amber">
        <p>Managers</p>
        <strong>{{ stats.managers }}</strong>
      </article>
      <article class="stat-card green">
        <p>Employés</p>
        <strong>{{ stats.employees }}</strong>
      </article>
    </div>

    <!-- Tableau utilisateurs -->
    <section class="admin-card users-card">
      <div class="card-heading">
        <div>
          <p class="card-kicker">ACCÈS</p>
          <h2>Droits et Rôles</h2>
        </div>
        <div class="card-heading-actions"><span class="card-count">{{ filteredUsers.length }} / {{ users.length }} utilisateurs</span><button class="action-button" type="button" @click="openUserModal">+ Ajouter un utilisateur</button></div>
      </div>

      <!-- Filtres -->
      <div class="filters-bar">
        <input
          v-model="searchQuery"
          type="search"
          placeholder="🔍 Rechercher par nom ou email…"
          class="filter-search"
        />
        <select v-model="roleFilter" class="filter-select">
          <option value="">Tous les rôles</option>
          <option value="admin">Admin</option>
          <option value="manager">Manager</option>
          <option value="employee">Employé</option>
        </select>
        <select v-model="statusFilter" class="filter-select">
          <option value="">Tous les statuts</option>
          <option value="active">Actif</option>
          <option value="suspended">Suspendu</option>
          <option value="terminated">Terminé</option>
        </select>
        <select v-model="teamFilter" class="filter-select"><option value="">Toutes les équipes</option><option v-for="team in teams" :key="team.id" :value="team.id">{{ team.name }}</option></select>
        <select v-model="sortBy" class="filter-select"><option value="username">Trier par nom</option><option value="contract_start">Trier par embauche</option></select>
        <button
          v-if="searchQuery || roleFilter || statusFilter || teamFilter"
          @click="resetFilters"
          class="filter-reset"
        >
          Réinitialiser
        </button>
      </div>

      <!-- Tableau -->
      <div class="table-container">
        <div class="users-table head">
          <span>Utilisateur</span>
          <span>Rôle</span>
          <span>Statut</span>
          <span>Actions</span>
        </div>
        <div v-for="user in paginatedUsers" :key="user.id" class="users-table">
          <span class="cell-user">
            <span class="avatar">{{ initials(user.username) }}</span>
            <span class="user-info">
              <b>{{ user.username }}</b>
              <small>{{ user.email }}</small>
            </span>
          </span>
          <span>
            <span class="badge" :class="roleBadgeClass(user.role)">
              {{ roleLabel(user.role) }}
            </span>
          </span>
          <span>
            <span class="status-badge" :class="statusBadgeClass(user.status)">
              ● {{ statusLabel(user.status) }}
            </span>
          </span>
          <span class="cell-actions">
            <button
              v-if="user.role === 'employee'"
              class="action-link"
              type="button"
              @click="changeRole(user.id, 'manager')"
            >
              ↑ Promouvoir
            </button>
            <button
              v-if="user.role === 'manager'"
              class="action-link danger"
              type="button"
              @click="changeRole(user.id, 'employee')"
            >
              ↓ Rétrograder
            </button>
            <span v-if="user.role === 'admin'" class="no-action">—</span>
          </span>
        </div>
        <p v-if="!paginatedUsers.length" class="empty-state">
          Aucun utilisateur ne correspond aux filtres.
        </p>
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="pagination">
        <button
          @click="goToPage(currentPage - 1)"
          :disabled="currentPage === 1"
          class="page-btn"
        >
          ← Précédent
        </button>
        <span class="page-info">
          Page {{ currentPage }} / {{ totalPages }}
          ({{ paginationRange.start }}-{{ paginationRange.end }} sur {{ filteredUsers.length }})
        </span>
        <button
          @click="goToPage(currentPage + 1)"
          :disabled="currentPage === totalPages"
          class="page-btn"
        >
          Suivant →
        </button>
      </div>
    </section>
    <div v-if="isUserModalOpen" class="modal-backdrop" @click.self="isUserModalOpen = false">
      <form class="modal-card" @submit.prevent="createAdminUser">
        <div class="card-heading"><h2>Nouvel utilisateur</h2><button class="modal-close" type="button" @click="isUserModalOpen = false">×</button></div>
        <p>Un mot de passe temporaire aléatoire sera généré. Il devra être changé à la première connexion.</p>
        <label class="modal-field">Nom d’utilisateur<input v-model="newUser.username" required></label>
        <label class="modal-field">Email<input v-model="newUser.email" type="email" required></label>
        <label class="modal-field">Rôle<select v-model="newUser.role"><option value="employee">Employé</option><option value="manager">Manager</option><option value="admin">Admin</option></select></label>
        <label class="modal-field">Statut<select v-model="newUser.status"><option value="active">Actif</option><option value="inactive">Inactif</option><option value="on_leave">En congé</option><option value="suspended">Suspendu</option><option value="terminated">Terminé</option></select></label>
        <div class="modal-actions"><button class="refresh-button" type="button" @click="isUserModalOpen = false">Annuler</button><button class="action-button" type="submit">Créer</button></div>
      </form>
    </div>
    <div v-if="temporaryCredentials" class="modal-backdrop">
      <section class="modal-card" role="dialog" aria-modal="true" aria-labelledby="temporary-password-title">
        <div class="card-heading"><h2 id="temporary-password-title">Compte créé</h2></div>
        <p>Communiquez ces identifiants à {{ temporaryCredentials.username }} par un canal sûr. Ce mot de passe ne sera affiché qu’une fois.</p>
        <label class="modal-field">Adresse e-mail<input :value="temporaryCredentials.email" readonly></label>
        <label class="modal-field">Mot de passe temporaire<input :value="temporaryCredentials.password" readonly autocomplete="off"></label>
        <p>Le changement du mot de passe sera obligatoire à la première connexion.</p>
        <div class="modal-actions">
          <button class="refresh-button" type="button" @click="copyTemporaryPassword">{{ copiedTemporaryPassword ? 'Copié' : 'Copier le mot de passe' }}</button>
          <button class="action-button" type="button" @click="temporaryCredentials = null">J’ai noté les identifiants</button>
        </div>
      </section>
    </div>

    <!-- Grille : équipes + absences -->
    <div class="admin-grid">
      <section class="admin-card team-management-card">
        <div class="card-heading">
          <div><p class="card-kicker">ORGANISATION</p><h2>Créer une équipe</h2></div>
          <span class="card-count">{{ teams.length }} équipes</span>
        </div>
        <form class="team-form" @submit.prevent="createTeam">
          <input v-model="newTeamName" required type="text" placeholder="Nom de l'équipe">
          <select v-model="newTeamManagerId" required>
            <option disabled value="">Choisir un manager</option>
            <option v-for="manager in managers" :key="manager.id" :value="manager.id">{{ manager.name }}</option>
          </select>
          <button class="action-link" type="submit">Créer</button>
        </form>
        <ul class="admin-list compact-list">
          <li v-for="team in teams" :key="team.id">
            <div><strong>{{ team.name }}</strong><span>{{ team.members.length }} membre{{ team.members.length > 1 ? 's' : '' }}</span></div>
            <div class="leave-actions">
              <span class="card-count" style="margin-right: 10px;">Manager #{{ team.manager_id }}</span>
              <button type="button" class="action-link danger" @click="deleteTeam(team.id)">Supprimer</button>
            </div>
          </li>
        </ul>
      </section>

      <section class="admin-card leave-card">
        <div class="card-heading">
          <div><p class="card-kicker">ABSENCES</p><h2>Demandes RH</h2></div>
          <span class="card-count">{{ leaveRequests.length }} à traiter</span>
        </div>
        <ul class="admin-list">
          <li v-for="request in leaveRequests" :key="request.id">
            <div><strong>{{ request.name }} · {{ request.type }}</strong><span>{{ request.start_date }} → {{ request.end_date }}</span></div>
            <div class="leave-actions">
              <button v-if="request.status === 'pending'" class="action-link success" type="button" @click="reviewLeave(request, 'approved')">✓ Approuver</button>
              <button v-if="request.status === 'pending'" class="action-link danger" type="button" @click="reviewLeave(request, 'rejected')">✗ Refuser</button>
              <span v-else class="card-count">{{ request.status }}</span>
            </div>
          </li>
        </ul>
      </section>
    </div>

    <!-- Cycle de vie RH -->
    <section class="admin-card lifecycle-card">
      <div class="card-heading">
        <div><p class="card-kicker">RH</p><h2>Cycle de vie des employés</h2></div>
        <span class="card-count">Joiner / Mover / Leaver</span>
      </div>
      <div class="lifecycle-list">
        <div v-for="user in users.filter(u => u.role !== 'admin').slice(0, 10)" :key="user.id" class="lifecycle-row">
          <span class="cell-user">
            <span class="avatar small">{{ initials(user.username) }}</span>
            <span class="user-info">
              <b>{{ user.username }}</b>
              <small>{{ user.email }}</small>
            </span>
          </span>
          <select v-model="user.status" class="mini-select">
            <option value="active">Actif</option>
            <option value="suspended">Suspendu</option>
            <option value="terminated">Terminé</option>
          </select>
          <input type="date" v-model="user.contract_start" class="mini-date" />
          <input type="date" v-model="user.contract_end" class="mini-date" />
          <button type="button" class="action-link" @click="updateUserLifecycle(user)">💾 Sauvegarder</button>
        </div>
        <p v-if="!users.length" class="empty-state">Aucun employé à afficher.</p>
      </div>
    </section>

    <!-- Règles de paie -->
    <section class="admin-card payroll-card">
      <div class="card-heading">
        <div><p class="card-kicker">PAIE</p><h2>Règles de majoration</h2></div>
        <div class="card-heading-actions"><span class="card-count">{{ payrollRules.length }} règles</span><button class="action-button" type="button" @click="openPayrollRuleModal()">+ Ajouter une règle</button></div>
      </div>
      <div v-if="payrollRules.length" class="rules-grid">
        <article v-for="rule in payrollRules" :key="rule.id" class="rule-card" :class="rule.tone">
          <span>{{ rule.label }}</span>
          <strong>{{ rule.value }}</strong>
          <small>{{ rule.active ? 'Active' : 'Inactive' }}</small>
          <div class="rule-actions"><button type="button" class="action-link" @click="openPayrollRuleModal(rule)">Modifier</button><button type="button" class="action-link danger" @click="deletePayrollRule(rule)">Supprimer</button></div>
        </article>
      </div>
      <p v-else class="empty-state">Aucune règle de paie définie. Contactez le service comptabilité.</p>
    </section>

    <div v-if="isPayrollRuleModalOpen" class="modal-backdrop" @click.self="closePayrollRuleModal">
      <form class="modal-card" @submit.prevent="savePayrollRule">
        <div class="card-heading"><div><p class="card-kicker">PAIE</p><h2>{{ editingPayrollRuleId ? 'Modifier la règle' : 'Ajouter une règle' }}</h2></div><button class="modal-close" type="button" aria-label="Fermer" @click="closePayrollRuleModal">×</button></div>
        <label class="modal-field">Nom<input v-model="payrollRuleForm.name" required type="text" placeholder="Majoration de nuit"></label>
        <label class="modal-field">Type<select v-model="payrollRuleForm.rule_type"><option value="night">Nuit</option><option value="overtime">Heures supplémentaires</option><option value="holiday">Jour férié</option><option value="weekend">Week-end</option></select></label>
        <label class="modal-field">Valeur<input v-model.number="payrollRuleForm.value" required min="0" step="0.01" type="number" placeholder="1.25"></label>
        <label class="modal-checkbox"><input v-model="payrollRuleForm.active" type="checkbox"> Règle active</label>
        <div class="modal-actions"><button class="refresh-button" type="button" @click="closePayrollRuleModal">Annuler</button><button class="action-button" type="submit">{{ editingPayrollRuleId ? 'Enregistrer' : 'Créer la règle' }}</button></div>
      </form>
    </div>

    <!-- Vigilance fatigue -->
    <section class="admin-card fatigue-card">
      <div class="card-heading">
        <div><p class="card-kicker">PRÉVENTION</p><h2>Vigilance fatigue</h2></div>
        <span class="card-count">{{ fatigueAlerts.length }} alerte{{ fatigueAlerts.length > 1 ? 's' : '' }}</span>
      </div>
      <ul v-if="fatigueAlerts.length" class="fatigue-list">
        <li v-for="alert in fatigueAlerts" :key="alert.name">
          <span class="alert-dot" aria-hidden="true"></span>
          <div><strong>{{ alert.name }}</strong><span>{{ alert.detail }}</span></div>
        </li>
      </ul>
      <p v-else class="empty-state">✅ Aucune alerte fatigue cette semaine.</p>
    </section>
  </section>
</template>

<style scoped>
.admin-page { --ink: #252522; --muted: #716b64; --line: rgba(37, 33, 27, .14); --copper: #a7673c; width: min(100%, 1120px); margin: 0 auto; color: var(--ink); padding-bottom: 40px; }

/* Header */
.admin-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 2rem; padding-bottom: 1.5rem; margin-bottom: 1.5rem; border-bottom: 1px solid var(--line); }
.eyebrow, .card-kicker { margin: 0 0 8px; color: #8a7cf0; font-size: 10px; font-weight: 800; letter-spacing: .12em; }
.admin-header h1 { margin: 0; font: 800 clamp(25px, 3.5vw, 34px) 'Manrope', sans-serif; letter-spacing: -.055em; line-height: 1.1; }
.admin-header p:not(.eyebrow) { max-width: 580px; margin: 8px 0 0; color: var(--muted); font-size: 13px; line-height: 1.6; }
.back-link { color: var(--ink); font-size: .75rem; font-weight: 800; white-space: nowrap; flex-shrink: 0; text-decoration: none; }
.back-link:hover { text-decoration: underline; }

/* Stats */
.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 18px; }
.stat-card { position: relative; padding: 18px; background: #fff; border: 1px solid var(--line); border-radius: 12px; overflow: hidden; box-shadow: 0 8px 25px #29375608; }
.stat-card p { margin: 0 0 8px; color: var(--muted); font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; }
.stat-card strong { color: var(--ink); font: 800 28px 'Manrope', sans-serif; letter-spacing: -.04em; }
.stat-card::before { content: ''; position: absolute; inset: 0 0 auto; height: 3px; }
.stat-card.blue::before { background: #5796e7; }
.stat-card.violet::before { background: #8b7ded; }
.stat-card.amber::before { background: #f0ad32; }
.stat-card.green::before { background: #43ae76; }

/* Carte */
.admin-card { padding: 1.35rem; background: #fff; border: 1px solid var(--line); border-radius: 12px; box-shadow: 0 12px 30px rgba(37, 33, 27, .05); margin-bottom: 18px; }
.card-heading { display: flex; align-items: start; justify-content: space-between; gap: 1rem; }
.card-heading-actions, .modal-actions, .rule-actions { display: flex; align-items: center; gap: .6rem; }
.action-button { padding: .55rem .8rem; color: #fff; background: #786be7; border: 1px solid #786be7; border-radius: 7px; font-size: .72rem; font-weight: 800; cursor: pointer; }
.action-button:hover { background: #6658ce; }
.card-heading h2 { margin: 0; font-size: 1.15rem; letter-spacing: -.04em; }
.card-count { color: var(--muted); font-size: .7rem; white-space: nowrap; }

/* Filtres */
.filters-bar { display: flex; gap: 10px; margin-top: 16px; flex-wrap: wrap; }
.filter-search { flex: 1; min-width: 200px; padding: 10px 14px; border: 1px solid var(--line); border-radius: 8px; font-size: 13px; color: var(--ink); background: #fff; }
.filter-search:focus { outline: 2px solid #8a7cf0; outline-offset: -1px; }
.filter-select { padding: 10px 14px; border: 1px solid var(--line); border-radius: 8px; font-size: 13px; color: var(--ink); background: #fff; cursor: pointer; }
.filter-reset { padding: 10px 16px; border: 1px solid var(--line); border-radius: 8px; background: #fff; font-size: 12px; font-weight: 700; color: var(--muted); cursor: pointer; }
.filter-reset:hover { background: #f5f5f5; }

/* Tableau utilisateurs */
.table-container { margin-top: 16px; }
.users-table { display: grid; grid-template-columns: 2fr 1fr 1fr 1.2fr; align-items: center; gap: 16px; padding: 14px 8px; border-bottom: 1px solid #edf0f4; font-size: 13px; }
.users-table.head { padding: 8px; color: var(--muted); font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; border-bottom: 2px solid #edf0f4; }
.cell-user { display: flex; align-items: center; gap: 12px; }
.avatar { display: grid; width: 38px; height: 38px; place-items: center; color: #655bd0; font-size: 13px; font-weight: 800; background: #e9e7ff; border-radius: 50%; flex-shrink: 0; }
.avatar.small { width: 30px; height: 30px; font-size: 11px; }
.user-info { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.user-info b { color: var(--ink); font-size: 13px; }
.user-info small { color: var(--muted); font-size: 11px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

/* Badges */
.badge { display: inline-block; padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 700; }
.badge-admin { color: #3f71af; background: #eff6ff; }
.badge-manager { color: #655bd0; background: #e9e7ff; }
.badge-employee { color: #3a8c5f; background: #e8f7ee; }
.status-badge { display: inline-block; padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 700; }
.status-active { color: #3a8c5f; background: #e8f7ee; }
.status-suspended { color: #8e6818; background: #fff8df; }
.status-terminated { color: #b6444d; background: #fff0f1; }
.no-action { color: var(--muted); font-size: 12px; }

/* Actions */
.action-link { color: var(--copper); background: transparent; border: 0; font-size: 12px; font-weight: 700; cursor: pointer; padding: 4px 8px; border-radius: 4px; }
.action-link:hover { background: #f5f5f5; }
.action-link.danger { color: #e85d65; }
.action-link.success { color: #43ae76; }

/* Pagination */
.pagination { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-top: 20px; padding-top: 16px; border-top: 1px solid #edf0f4; }
.page-btn { padding: 8px 16px; border: 1px solid var(--line); border-radius: 6px; background: #fff; font-size: 12px; font-weight: 700; cursor: pointer; }
.page-btn:hover:not(:disabled) { background: #f5f5f5; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-info { color: var(--muted); font-size: 12px; }

/* Grille équipes + absences */
.admin-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }
.admin-list { display: grid; gap: 0; margin: 1.2rem 0 0; padding: 0; list-style: none; }
.admin-list li { display: flex; align-items: center; justify-content: space-between; gap: 1rem; padding: .85rem 0; border-top: 1px solid var(--line); }
.admin-list strong { font-size: .85rem; display: block; }
.admin-list span { margin-top: .25rem; color: var(--muted); font-size: .72rem; display: block; }

/* Formulaire équipe */
.team-form { display: grid; grid-template-columns: 1.2fr 1fr auto; gap: .6rem; margin-top: 1rem; }
.team-form input, .team-form select { min-height: 40px; padding: .55rem .65rem; color: var(--ink); background: #fff; border: 1px solid var(--line); border-radius: 6px; }
.team-form .action-link { padding: .55rem .8rem; border: 1px solid var(--line); border-radius: 6px; cursor: pointer; }

/* Lifecycle */
.lifecycle-list { margin-top: 16px; }
.lifecycle-row { display: grid; grid-template-columns: 2fr 1fr 1fr 1fr auto; align-items: center; gap: 12px; padding: 12px 8px; border-bottom: 1px solid #edf0f4; }
.mini-select, .mini-date { padding: 6px 8px; border: 1px solid var(--line); border-radius: 6px; font-size: 12px; }

/* Règles de paie */
.rules-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; margin-top: 1.2rem; }
.rule-card { padding: 1rem; border-radius: 8px; border-top: 3px solid; }
.rule-card span { color: var(--muted); font-size: .72rem; display: block; }
.rule-card strong { margin-top: .5rem; font-size: 1.35rem; display: block; }
.rule-card small { display: block; margin-top: .4rem; color: var(--muted); font-size: .68rem; }
.rule-actions { margin-top: .8rem; }
.action-link.danger { color: #b6444d; }
.modal-backdrop { position: fixed; inset: 0; z-index: 100; display: grid; place-items: center; padding: 1rem; background: rgba(20, 20, 25, .45); }
.modal-card { display: grid; gap: 1rem; width: min(100%, 460px); padding: 1.4rem; background: #fff; border-radius: 12px; box-shadow: 0 20px 60px rgba(0, 0, 0, .2); }
.modal-close { color: var(--muted); background: transparent; border: 0; font-size: 1.5rem; cursor: pointer; }
.modal-field { display: grid; gap: .4rem; color: var(--muted); font-size: .75rem; font-weight: 800; }
.modal-field input, .modal-field select { min-height: 40px; padding: .55rem .65rem; color: var(--ink); background: #fff; border: 1px solid var(--line); border-radius: 7px; font-size: .85rem; }
.modal-checkbox { display: flex; align-items: center; gap: .5rem; color: var(--ink); font-size: .8rem; }
.modal-actions { justify-content: flex-end; margin-top: .4rem; }
.rule-card.violet { color: #6658ce; background: #f3f1ff; border-color: #887ce8; }
.rule-card.amber { color: #8e6818; background: #fff8df; border-color: #f0ad32; }
.rule-card.blue { color: #3f71af; background: #eff6ff; border-color: #5796e7; }

/* Alertes fatigue */
.fatigue-list { display: grid; gap: 0; margin: 1.2rem 0 0; padding: 0; list-style: none; }
.fatigue-list li { display: flex; align-items: center; gap: 12px; padding: .85rem 0; border-top: 1px solid var(--line); }
.alert-dot { width: 9px; height: 9px; flex: 0 0 auto; background: #e85d65; border-radius: 50%; box-shadow: 0 0 0 5px #fff0f1; }

/* États vides */
.empty-state { padding: 24px 0; color: var(--muted); font-size: 13px; text-align: center; }
.demo-notice { margin: 1.5rem 0 0; padding: 12px 14px; color: #6f5a1b; font-size: .8rem; background: #fff8df; border-left: 3px solid #f0ad32; }

/* Responsive */
@media (max-width: 760px) {
  .admin-page { padding: 0 16px; }
  .admin-header { display: block; }
  .back-link { display: inline-block; margin-top: 1rem; }
  .admin-grid, .rules-grid, .stats-grid { grid-template-columns: 1fr; }
  .users-table { grid-template-columns: 1fr; gap: 8px; padding: 16px; }
  .users-table.head { display: none; }
  .lifecycle-row { grid-template-columns: 1fr; }
}
</style>
