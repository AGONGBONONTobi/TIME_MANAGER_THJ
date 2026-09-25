<template>
  <section class="timeline-page">
    <div class="timeline-header">
      <div>
        <p class="eyebrow">Journal d'activité · utilisateur {{ userId }}</p>
        <h1>La journée, <em>en mouvement.</em></h1>
        <p class="intro">Chaque session devient un repère. Suis le rythme du travail sans perdre le fil.</p>
      </div>
        <div class="header-actions">
        <button class="refresh-button" type="button" :disabled="isLoading" @click="getWorkingTimes">Actualiser</button>
        <router-link :to="`/workingTime/${userId}`" class="new-session">Nouvelle session</router-link>
      </div>
    </div>

    <div class="timeline-summary">
      <div><span class="summary-label">Sessions visibles</span><strong>{{ workingTimes.length }}</strong></div>
      <div><span class="summary-label">Temps cumulé</span><strong>{{ totalDuration }}</strong></div>
      <div><span class="summary-label">État actuel</span><strong class="summary-state"><i :class="{ active: hasActiveSession }"></i>{{ hasActiveSession ? 'En cours' : 'Au repos' }}</strong></div>
    </div>

    <div v-if="workingTimes.length" class="timeline" aria-label="Historique des working times">
      <article v-for="(wt, index) in sortedWorkingTimes" :key="wt.id" class="timeline-item" :class="{ active: !wt.end }">
        <div class="timeline-rail"><span class="timeline-dot"></span><span v-if="index < sortedWorkingTimes.length - 1" class="timeline-line"></span></div>
        <div class="session-card">
          <div class="session-topline"><span class="session-index">0{{ sortedWorkingTimes.length - index }}</span><span class="session-date">{{ formatDate(wt.start) }}</span><span v-if="!wt.end" class="active-label">Session en cours</span></div>
          <div class="session-main">
            <div><h2>{{ formatTime(wt.start) }} à {{ wt.end ? formatTime(wt.end) : 'maintenant' }}</h2><p>{{ wt.end ? 'Session clôturée' : 'Le chronomètre tourne actuellement' }}</p></div>
            <div class="session-duration"><span>durée</span><strong>{{ duration(wt) }}</strong></div>
          </div>
          <div class="session-footer"><span>Référence #{{ wt.id }}</span><router-link :to="`/workingTime/${userId}/${wt.id}`">Modifier</router-link></div>
        </div>
      </article>
    </div>
    <div v-else class="empty-state"><span class="empty-number">00</span><div><h2>Aucune session enregistrée</h2><p>La première entrée de cette timeline est encore à écrire.</p></div><router-link :to="`/workingTime/${userId}`" class="new-session">Commencer</router-link></div>
  </section>
</template>

<script>
import api from '../services/api'

export default {
  name: 'WorkingTimes',
  data() {
    return { userId: this.$route.params.userID, workingTimes: [], isLoading: false }
  },
  computed: {
    sortedWorkingTimes() { return [...this.workingTimes].sort((a, b) => new Date(b.start) - new Date(a.start)) },
    hasActiveSession() { return this.workingTimes.some((workingTime) => !workingTime.end) },
    totalDuration() {
      const minutes = this.workingTimes.reduce((total, workingTime) => total + this.durationInMinutes(workingTime), 0)
      return minutes >= 60 ? `${Math.floor(minutes / 60)}h ${minutes % 60}m` : `${minutes}m`
    }
  },
  mounted() { this.getWorkingTimes() },
  watch: {
    '$route.params.userID'(newId) { this.userId = newId; this.getWorkingTimes() }
  },
  methods: {
    async getWorkingTimes() {
      this.isLoading = true
      try {
        const response = await api.getWorkingTimes(this.userId)
        this.workingTimes = response.data.data
      } catch (error) {
        console.error(error)
      } finally {
        this.isLoading = false
      }
    },
    durationInMinutes(workingTime) {
      const end = workingTime.end ? new Date(workingTime.end) : new Date()
      return Math.max(0, Math.round((end - new Date(workingTime.start)) / 60000))
    },
    duration(workingTime) {
      const minutes = this.durationInMinutes(workingTime)
      return minutes >= 60 ? `${Math.floor(minutes / 60)}h ${minutes % 60}m` : `${minutes} min`
    },
    formatDate(value) { return new Intl.DateTimeFormat('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(value)) },
    formatTime(value) { return new Intl.DateTimeFormat('fr-FR', { hour: '2-digit', minute: '2-digit' }).format(new Date(value)) }
  }
}
</script>

<style scoped>
.timeline-page { --ink: #252522; --muted: #716b64; --paper: #fbf8f3; --line: rgba(37, 33, 27, .14); --copper: #a7673c; --blush: #ead8c6; width: min(100%, 980px); margin: 5rem auto 3rem; color: var(--ink); }
.timeline-header { display: flex; align-items: end; justify-content: space-between; gap: 2rem; padding-bottom: 2rem; border-bottom: 1px solid var(--line); }.eyebrow { margin: 0 0 .7rem; color: var(--copper); font-size: .7rem; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; }.timeline-header h1 { max-width: 650px; margin: 0; font-size: clamp(2.7rem, 7vw, 5.9rem); line-height: .92; letter-spacing: -.075em; }.timeline-header h1 em { color: var(--copper); font-family: Georgia, serif; font-weight: 400; }.intro { max-width: 500px; margin: 1rem 0 0; color: var(--muted); line-height: 1.6; }.header-actions { display: flex; flex-direction: column; align-items: end; gap: .75rem; }.refresh-button, .new-session { display: inline-flex; align-items: center; justify-content: center; min-height: 42px; padding: .7rem 1rem; border: 1px solid var(--line); border-radius: 0; font-size: .75rem; font-weight: 800; text-decoration: none; transition: transform .2s ease, background .2s ease; }.refresh-button { color: var(--ink); background: transparent; }.new-session { color: #fff; background: var(--ink); border-color: var(--ink); }.new-session span { margin-left: .75rem; font-size: 1rem; }.refresh-button:hover, .new-session:hover { transform: translateY(-2px); }.new-session:hover { background: var(--copper); border-color: var(--copper); }
.timeline-summary { display: grid; grid-template-columns: repeat(3, 1fr); margin: 1.4rem 0 2.7rem; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }.timeline-summary > div { padding: 1rem 1.2rem; border-right: 1px solid var(--line); }.timeline-summary > div:last-child { border-right: 0; }.summary-label { display: block; margin-bottom: .35rem; color: var(--muted); font-size: .68rem; font-weight: 700; letter-spacing: .08em; text-transform: uppercase; }.timeline-summary strong { font-size: 1.35rem; letter-spacing: -.04em; }.summary-state { display: flex; align-items: center; gap: .45rem; }.summary-state i { width: 7px; height: 7px; background: #96918a; border-radius: 50%; }.summary-state i.active { background: #638b63; box-shadow: 0 0 0 4px rgba(99, 139, 99, .15); }
.timeline-item { display: grid; grid-template-columns: 36px 1fr; gap: 1rem; }.timeline-rail { position: relative; display: flex; justify-content: center; }.timeline-dot { z-index: 1; width: 14px; height: 14px; margin-top: 1.5rem; background: var(--paper); border: 3px solid var(--copper); border-radius: 50%; }.timeline-line { position: absolute; top: 2.2rem; bottom: -1.4rem; width: 1px; background: var(--line); }.timeline-item.active .timeline-dot { background: var(--copper); box-shadow: 0 0 0 7px rgba(167, 103, 60, .12); }.session-card { margin-bottom: 1.4rem; padding: 1.25rem 1.4rem 1rem; background: #fff; border: 1px solid var(--line); transition: transform .25s ease, box-shadow .25s ease; }.session-card:hover { transform: translateX(4px); box-shadow: 0 14px 28px rgba(37, 33, 27, .08); }.session-topline, .session-footer { display: flex; align-items: center; gap: .75rem; color: var(--muted); font-size: .68rem; font-weight: 700; letter-spacing: .06em; text-transform: uppercase; }.session-index { color: var(--copper); }.session-date { margin-right: auto; }.active-label { color: #638b63; }.session-main { display: flex; align-items: end; justify-content: space-between; gap: 1rem; padding: 1.3rem 0 1.1rem; }.session-main h2 { margin: 0; font-size: clamp(1.5rem, 4vw, 2.6rem); letter-spacing: -.065em; }.session-main h2 span { color: var(--copper); font-family: Georgia, serif; font-weight: 400; }.session-main p { margin: .4rem 0 0; color: var(--muted); font-size: .8rem; }.session-duration { padding-left: 1rem; text-align: right; border-left: 1px solid var(--line); }.session-duration span { display: block; margin-bottom: .25rem; color: var(--muted); font-size: .65rem; text-transform: uppercase; }.session-duration strong { white-space: nowrap; font-size: 1.1rem; }.session-footer { justify-content: space-between; padding-top: .8rem; border-top: 1px solid var(--line); }.session-footer a { color: var(--ink); text-decoration: none; }.session-footer a span { color: var(--copper); }.empty-state { display: flex; align-items: center; gap: 1.4rem; padding: 2rem; background: var(--blush); }.empty-number { color: var(--copper); font-size: 3rem; font-weight: 800; letter-spacing: -.08em; }.empty-state h2 { margin: 0; font-size: 1.25rem; }.empty-state p { margin: .4rem 0 0; color: var(--muted); }.empty-state .new-session { margin-left: auto; white-space: nowrap; }
@media (max-width: 680px) { .timeline-page { width: min(100% - 1rem, 980px); margin-top: 3rem; }.timeline-header { display: block; }.header-actions { align-items: stretch; flex-direction: row; margin-top: 1.5rem; }.header-actions > * { flex: 1; }.timeline-summary { grid-template-columns: 1fr; }.timeline-summary > div { display: flex; align-items: center; justify-content: space-between; border-right: 0; border-bottom: 1px solid var(--line); }.timeline-summary > div:last-child { border-bottom: 0; }.session-card { padding: 1rem; }.session-main { align-items: start; flex-direction: column; }.session-duration { padding: .6rem 0 0; text-align: left; border-top: 1px solid var(--line); border-left: 0; }.empty-state { align-items: start; flex-wrap: wrap; }.empty-state .new-session { width: 100%; margin-left: 0; } }
</style>