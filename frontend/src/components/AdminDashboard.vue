<script>
export default {
  name: 'AdminDashboard',
  data() {
    return {
      managers: [
        { id: 1, name: 'Sophie Laurent', scope: 'Équipe Gotham', active: true },
        { id: 2, name: 'Karim Benali', scope: 'Équipe de nuit', active: true }
      ],
      leaveRequests: [
        { id: 1, name: 'Amélie Rousseau', type: 'Congé', dates: '12–16 octobre', status: 'À traiter' },
        { id: 2, name: 'Thomas Petit', type: 'Maladie', dates: '07 octobre', status: 'À traiter' }
      ],
      payrollRules: [
        { label: 'Heures de nuit', value: '× 1,5', tone: 'violet' },
        { label: 'Heures supplémentaires', value: '× 2', tone: 'amber' },
        { label: 'Seuil hebdomadaire', value: '35 h', tone: 'blue' }
      ],
      fatigueAlerts: [
        { name: 'Karim Benali', detail: '4 nuits cette semaine · repos à vérifier' },
        { name: 'Joseph Martin', detail: '3 nuits consécutives · surveillance recommandée' }
      ]
    }
  },
  methods: {
    revokeManager(manager) {
      manager.active = false
    },
    approveLeave(request) {
      request.status = 'Validée en démo'
    }
  }
}
</script>

<template>
  <section class="admin-page">
    <header class="admin-header">
      <div>
        <p class="eyebrow">ADMINISTRATION · RH · COMPTABILITÉ</p>
        <h1>Gouverner le temps.</h1>
        <p>Le troisième parcours rassemble les règles, les absences et les accès. Cette version prépare l’interface avant les endpoints backend.</p>
      </div>
      <router-link class="back-link" :to="{ name: 'user' }">Retour à l’espace utilisateur</router-link>
    </header>

    <p class="demo-notice" role="status"><strong>Prototype frontend.</strong> Les actions de cette page modifient uniquement l’état local. Les droits réels seront contrôlés côté backend.</p>

    <div class="admin-grid">
      <section class="admin-card access-card">
        <div class="card-heading"><div><p class="card-kicker">ACCÈS</p><h2>Droits des managers</h2></div><span class="card-count">{{ managers.filter(manager => manager.active).length }} actifs</span></div>
        <ul class="admin-list">
          <li v-for="manager in managers" :key="manager.id">
            <div><strong>{{ manager.name }}</strong><span>{{ manager.scope }}</span></div>
            <button class="action-link" type="button" :disabled="!manager.active" @click="revokeManager(manager)">{{ manager.active ? 'Révoquer' : 'Révoqué en démo' }}</button>
          </li>
        </ul>
      </section>

      <section class="admin-card leave-card">
        <div class="card-heading"><div><p class="card-kicker">ABSENCES</p><h2>Demandes RH</h2></div><span class="card-count">{{ leaveRequests.length }} à traiter</span></div>
        <ul class="admin-list">
          <li v-for="request in leaveRequests" :key="request.id">
            <div><strong>{{ request.name }} · {{ request.type }}</strong><span>{{ request.dates }}</span></div>
            <button class="action-link" type="button" @click="approveLeave(request)">{{ request.status }}</button>
          </li>
        </ul>
      </section>
    </div>

    <section class="admin-card payroll-card">
      <div class="card-heading"><div><p class="card-kicker">PAIE</p><h2>Règles de majoration</h2></div><span class="card-count">Configuration locale</span></div>
      <div class="rules-grid"><article v-for="rule in payrollRules" :key="rule.label" class="rule-card" :class="rule.tone"><span>{{ rule.label }}</span><strong>{{ rule.value }}</strong></article></div>
    </section>

    <section class="admin-card fatigue-card">
      <div class="card-heading"><div><p class="card-kicker">PRÉVENTION</p><h2>Vigilance fatigue</h2></div><span class="card-count">{{ fatigueAlerts.length }} alertes</span></div>
      <ul class="fatigue-list"><li v-for="alert in fatigueAlerts" :key="alert.name"><span class="alert-dot" aria-hidden="true"></span><div><strong>{{ alert.name }}</strong><span>{{ alert.detail }}</span></div></li></ul>
    </section>
  </section>
</template>

<style scoped>
.admin-page { --ink: #252522; --muted: #716b64; --line: rgba(37, 33, 27, .14); --copper: #a7673c; width: min(100%, 1120px); margin: 4rem auto 3rem; color: var(--ink); }.admin-header { display: flex; align-items: end; justify-content: space-between; gap: 2rem; padding-bottom: 2rem; border-bottom: 1px solid var(--line); }.eyebrow, .card-kicker { margin: 0 0 .7rem; color: var(--copper); font-size: .7rem; font-weight: 800; letter-spacing: .14em; }.admin-header h1 { margin: 0; font-size: clamp(2.7rem, 7vw, 5.8rem); line-height: .92; letter-spacing: -.075em; }.admin-header p:not(.eyebrow) { max-width: 580px; margin: 1rem 0 0; color: var(--muted); line-height: 1.6; }.back-link { color: var(--ink); font-size: .75rem; font-weight: 800; white-space: nowrap; }.demo-notice { margin: 1.5rem 0 0; padding: 12px 14px; color: #6f5a1b; font-size: .8rem; background: #fff8df; border-left: 3px solid #f0ad32; }.admin-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; margin-top: 18px; }.admin-card { padding: 1.35rem; background: #fff; border: 1px solid var(--line); box-shadow: 0 12px 30px rgba(37, 33, 27, .05); }.card-heading { display: flex; align-items: start; justify-content: space-between; gap: 1rem; }.card-kicker { margin-bottom: .4rem; }.card-heading h2 { margin: 0; font-size: 1.15rem; letter-spacing: -.04em; }.card-count { color: var(--muted); font-size: .7rem; white-space: nowrap; }.admin-list, .fatigue-list { display: grid; gap: 0; margin: 1.2rem 0 0; padding: 0; list-style: none; }.admin-list li, .fatigue-list li { display: flex; align-items: center; justify-content: space-between; gap: 1rem; padding: .85rem 0; border-top: 1px solid var(--line); }.admin-list strong, .admin-list span, .fatigue-list strong, .fatigue-list span { display: block; }.admin-list strong, .fatigue-list strong { font-size: .8rem; }.admin-list span, .fatigue-list span { margin-top: .25rem; color: var(--muted); font-size: .72rem; }.action-link { color: var(--copper); background: transparent; border: 0; font-size: .72rem; font-weight: 800; cursor: pointer; }.action-link:disabled { color: #9a958e; cursor: default; }.payroll-card, .fatigue-card { margin-top: 18px; }.rules-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-top: 1.2rem; }.rule-card { padding: 1rem; border-top: 3px solid; }.rule-card span, .rule-card strong { display: block; }.rule-card span { color: var(--muted); font-size: .72rem; }.rule-card strong { margin-top: .7rem; font-size: 1.55rem; }.rule-card.violet { color: #6658ce; background: #f3f1ff; border-color: #887ce8; }.rule-card.amber { color: #8e6818; background: #fff8df; border-color: #f0ad32; }.rule-card.blue { color: #3f71af; background: #eff6ff; border-color: #5796e7; }.alert-dot { width: 9px; height: 9px; flex: 0 0 auto; margin-right: .2rem; background: #e85d65; border-radius: 50%; box-shadow: 0 0 0 5px #fff0f1; }.fatigue-list li { justify-content: start; }
@media (max-width: 760px) { .admin-page { width: min(100% - 1rem, 1120px); margin-top: 2.5rem; }.admin-header { display: block; }.back-link { display: inline-block; margin-top: 1.5rem; }.admin-grid, .rules-grid { grid-template-columns: 1fr; } }
</style>
