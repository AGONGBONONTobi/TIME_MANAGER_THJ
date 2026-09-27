<template>
  <div class="user-page">
    <HeroSection />
    <section class="user-console" aria-labelledby="user-console-title">
      <div class="section-heading">
        <div>
          <p class="eyebrow">Administration · identité</p>
          <h2 id="user-console-title">Le poste de commande</h2>
          <p class="section-intro">Retrouvez un profil, ajustez ses accès et gardez une trace nette de chaque action.</p>
        </div>
        <div class="record-mark" aria-hidden="true"><span>TM</span><small>FILE<br />{{ userId || 'Aucun' }}</small></div>
      </div>
        <div class="console-grid">
        <form class="profile-panel" @submit.prevent="createUser">
          <div class="panel-topline"><span class="panel-kicker">01 / Profil</span><span class="live-indicator"><i></i> Prêt</span></div>
          <div class="form-grid">
            <label><span>Identifiant utilisateur</span><input v-model="userId" type="text" placeholder="ex. 42" /></label>
            <label><span>Nom d'utilisateur</span><input v-model="username" type="text" placeholder="Nom affiché" required /></label>
            <label class="wide-field"><span>Adresse email</span><input v-model="email" type="email" placeholder="nom@exemple.com" required /></label>
          </div>
          <div class="action-row">
            <button class="button button-dark" type="submit" :disabled="isLoading">Créer le profil</button>
            <button class="button button-light" type="button" :disabled="isLoading" @click="getUser">Charger</button>
            <button class="button button-outline" type="button" :disabled="isLoading || !userId" @click="updateUser">Mettre à jour</button>
            <button class="button button-danger" type="button" :disabled="isLoading || !userId" @click="deleteUser">Supprimer</button>
          </div>
        </form>
        <aside class="identity-panel">
          <div class="identity-stamp">IDENTITÉ ACTIVE</div>
          <div v-if="user" class="identity-content">
            <div class="avatar">{{ initials }}</div><p class="identity-label">Compte sélectionné</p><h3>{{ user.username }}</h3>
            <p>{{ user.email || email || 'Aucune adresse renseignée' }}</p><div class="identity-meta"><span>ID</span><strong>{{ user.id }}</strong></div>
          </div>
          <div v-else class="empty-identity"><span class="empty-line"></span><p>Aucun dossier ouvert</p><small>Charge un utilisateur pour faire apparaître son identité ici.</small></div>
        </aside>
      </div>
      <p v-if="statusMessage" class="status-message" :class="`is-${statusKind}`" role="status">{{ statusMessage }}</p>
    </section>
  </div>
</template>

<script>
import HeroSection from './HeroSection.vue'
import api from '../services/api'

export default {
  name: 'UserPage',
  components: { HeroSection },
  data() { return { userId: '', username: '', email: '', user: null, isLoading: false, statusMessage: '', statusKind: 'neutral' } },
  computed: {
    initials() { return (this.user?.username || this.username || 'U').split(' ').map((part) => part[0]).join('').slice(0, 2).toUpperCase() }
  },
  methods: {
    setStatus(message, kind = 'neutral') { this.statusMessage = message; this.statusKind = kind },
    async getUser() {
      if (!this.userId) return this.setStatus('Indique un identifiant avant de charger un profil.', 'error')
      this.isLoading = true
      try { const response = await api.getUser(this.userId); this.user = response.data.data; this.username = this.user.username || ''; this.email = this.user.email || ''; this.setStatus('Profil chargé.', 'success') }
      catch { this.setStatus('Impossible de charger ce profil.', 'error') } finally { this.isLoading = false }
    },
    async createUser() {
      this.isLoading = true
      try { const response = await api.createUser({ username: this.username, email: this.email }); this.user = response.data.data; this.userId = this.user.id; this.setStatus('Profil créé avec succès.', 'success') }
      catch { this.setStatus('La création du profil a échoué.', 'error') } finally { this.isLoading = false }
    },
    async updateUser() {
      this.isLoading = true
      try { const response = await api.updateUser(this.userId, { username: this.username, email: this.email }); this.user = response.data.data; this.setStatus('Profil mis à jour.', 'success') }
      catch { this.setStatus('La mise à jour du profil a échoué.', 'error') } finally { this.isLoading = false }
    },
    async deleteUser() {
      this.isLoading = true
      try { await api.deleteUser(this.userId); this.user = null; this.username = ''; this.email = ''; this.setStatus('Profil supprimé.', 'success') }
      catch { this.setStatus('La suppression du profil a échoué.', 'error') } finally { this.isLoading = false }
    }
  }
}
</script>

<style scoped>
.user-page { --ink: #252522; --muted: #716b64; --paper: #fbf8f3; --line: rgba(37,33,27,.13); --copper: #a7673c; --blush: #ead8c6; padding-bottom: 3rem; }
.user-console { width: min(100% - 2rem,980px); margin: 2rem auto 0; padding: 2rem; position: relative; z-index: 1; color: var(--ink); background: var(--paper); border: 1px solid rgba(37,33,27,.08); box-shadow: 0 24px 55px rgba(37,33,27,.14); }
.section-heading { display:flex; justify-content:space-between; gap:2rem; padding-bottom:1.5rem; border-bottom:1px solid var(--line); }.eyebrow,.panel-kicker,.identity-stamp { margin:0 0 .55rem; color:var(--copper); font-size:.7rem; font-weight:800; letter-spacing:.16em; text-transform:uppercase; }.section-heading h2 { margin:0; font-size:clamp(1.8rem,4vw,3.1rem); letter-spacing:-.055em; }.section-intro { max-width:540px; margin:.7rem 0 0; color:var(--muted); line-height:1.6; }.record-mark { display:flex; align-items:center; gap:.65rem; align-self:start; color:var(--muted); font-size:.58rem; font-weight:800; letter-spacing:.1em; line-height:1.35; }.record-mark span { display:grid; width:44px; height:44px; place-items:center; color:var(--paper); background:var(--ink); border-radius:50%; }
.console-grid { display:grid; grid-template-columns:1.45fr .75fr; gap:1rem; margin-top:1rem; }.profile-panel,.identity-panel { min-height:305px; padding:1.35rem; border:1px solid var(--line); }.profile-panel { background:#fff; }.identity-panel { position:relative; overflow:hidden; background:var(--blush); }.identity-panel::before { position:absolute; right:-35px; bottom:-55px; width:170px; height:170px; content:''; border:1px solid rgba(167,103,60,.35); border-radius:50%; box-shadow:0 0 0 18px rgba(167,103,60,.07),0 0 0 38px rgba(167,103,60,.05); }.panel-topline { display:flex; justify-content:space-between; margin-bottom:1.6rem; }.live-indicator { color:var(--muted); font-size:.72rem; font-weight:700; }.live-indicator i { display:inline-block; width:7px; height:7px; margin-right:.3rem; background:#638b63; border-radius:50%; }
.form-grid { display:grid; grid-template-columns:1fr 1fr; gap:1rem; }label span { display:block; margin-bottom:.4rem; color:var(--muted); font-size:.76rem; font-weight:700; }input { width:100%; min-height:46px; padding:.7rem .8rem; color:var(--ink); background:var(--paper); border:1px solid var(--line); border-radius:0; outline:none; }input:focus { border-color:var(--copper); box-shadow:0 0 0 3px rgba(167,103,60,.13); }.wide-field { grid-column:1 / -1; }.action-row { display:flex; flex-wrap:wrap; gap:.55rem; margin-top:1.5rem; }.button { min-height:40px; padding:.65rem .85rem; border:1px solid transparent; border-radius:0; font-size:.75rem; font-weight:800; transition:transform .2s ease,background .2s ease; }.button:hover:not(:disabled) { transform:translateY(-2px); }.button:disabled { cursor:not-allowed; opacity:.45; }.button-dark { color:#fff; background:var(--ink); }.button-dark:hover:not(:disabled) { background:var(--copper); }.button-light { color:var(--ink); background:var(--blush); }.button-outline { color:var(--ink); background:transparent; border-color:var(--line); }.button-danger { color:#8a3e32; background:#f7e8e3; }
.identity-stamp { color:var(--ink); opacity:.65; }.identity-content { position:relative; z-index:1; margin-top:2rem; }.avatar { display:grid; width:62px; height:62px; margin-bottom:1.2rem; place-items:center; color:var(--paper); font-size:1.1rem; font-weight:800; background:var(--ink); border-radius:50%; }.identity-label { margin:0 0 .35rem; color:var(--muted); font-size:.73rem; text-transform:uppercase; }.identity-content h3 { margin:0; font-size:1.65rem; letter-spacing:-.05em; }.identity-content > p:not(.identity-label) { margin:.35rem 0 1.4rem; color:var(--muted); overflow-wrap:anywhere; }.identity-meta { display:flex; justify-content:space-between; padding-top:.8rem; border-top:1px solid rgba(37,33,27,.16); color:var(--muted); font-size:.72rem; }.identity-meta strong { color:var(--ink); }.empty-identity { position:relative; z-index:1; margin-top:5rem; color:var(--muted); }.empty-line { display:block; width:44px; height:3px; margin-bottom:1rem; background:var(--copper); }.empty-identity p { margin:0 0 .35rem; color:var(--ink); font-weight:800; }.empty-identity small { line-height:1.5; }.status-message { margin:1rem 0 0; padding:.8rem 1rem; border-left:3px solid var(--ink); background:#fff; font-size:.85rem; }.status-message.is-success { border-color:#638b63; }.status-message.is-error { border-color:#a3483b; }
@media (max-width:700px) { .user-console { width:min(100% - 1rem,980px); margin-top:1.25rem; padding:1.1rem; }.record-mark { display:none; }.console-grid { grid-template-columns:1fr; }.identity-panel { min-height:260px; }.form-grid { grid-template-columns:1fr; }.wide-field { grid-column:auto; } }
</style>
