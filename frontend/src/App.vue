<script>
export default {
  name: 'App',
  data() {
    return { currentUserId: 1, isNavOpen: false, isProfileOpen: false }
  },
  methods: {
    closeNav() { this.isNavOpen = false },
    toggleNav() { this.isNavOpen = !this.isNavOpen },
    handleEscape(event) {
      if (event.key === 'Escape') { this.isNavOpen = false; this.isProfileOpen = false }
    }
  },
  mounted() { window.addEventListener('keydown', this.handleEscape) },
  beforeUnmount() { window.removeEventListener('keydown', this.handleEscape) }
}
</script>

<template>
  <div class="app-shell">
    <div v-if="isNavOpen" class="mobile-scrim" aria-hidden="true" @click="closeNav"></div>
    <aside class="sidebar" :class="{ 'is-open': isNavOpen }">
      <div class="brand"><span class="brand-symbol"><i></i></span><span>Time Manager</span></div>
      <nav class="sidebar-nav" aria-label="Navigation principale">
        <p class="nav-section-title">Navigation</p>
        <router-link class="sidebar-link" :class="{ 'is-selected': $route.name === 'user' }" :to="{ name: 'user' }" @click="closeNav"><span class="nav-icon">⌂</span><span>Tableau de bord</span><span class="nav-arrow">›</span></router-link>
        <router-link class="sidebar-link" :class="{ 'is-selected': $route.name === 'hr' }" :to="{ name: 'hr' }" @click="closeNav"><span class="nav-icon">▦</span><span>Administration RH</span><span class="nav-arrow">›</span></router-link>
        <p class="nav-section-title nav-section-spaced">Mon espace</p>
        <router-link class="sidebar-link" :to="{ name: 'workingTimes', params: { userID: currentUserId } }" @click="closeNav"><span class="nav-icon">◷</span><span>Historique</span><span class="nav-arrow">›</span></router-link>
      </nav>
      <div class="sidebar-footer"><div class="sidebar-help"><span class="help-orb">?</span><div><strong>Besoin d'aide ?</strong><small>Consulter le centre d'aide</small></div></div><div class="sidebar-version">TIME MANAGER <span>v1.0</span></div></div>
    </aside>
    <div class="main-shell">
      <header class="topbar">
        <button class="menu-toggle" type="button" aria-label="Ouvrir la navigation" :aria-expanded="isNavOpen" @click="toggleNav"><span></span><span></span><span></span></button>
        <div class="page-heading"><span class="page-heading-dot"></span><span>Mon espace</span></div>
        <div class="topbar-actions">
          <button class="profile-button" type="button" @click="isProfileOpen = !isProfileOpen"><span class="avatar avatar-small">JW</span><span class="profile-copy"><strong>Joseph William</strong><small>Utilisateur</small></span><span class="profile-chevron">⌄</span></button>
          <div v-if="isProfileOpen" class="profile-menu"><strong>Joseph William</strong><span>Espace utilisateur</span><button type="button" @click="isProfileOpen = false">Fermer</button></div>
        </div>
      </header>
      <main class="app-content"><router-view /></main>
    </div>
  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@600;700;800&display=swap');
:root { font-family: 'DM Sans', sans-serif; color: #20242e; background: #f7f8fb; font-synthesis: none; }
* { box-sizing: border-box; } body { min-width: 320px; margin: 0; } button, input { font: inherit; }
.app-shell { min-height: 100vh; background: #f7f8fb; }.sidebar { position: fixed; z-index: 20; inset: 0 auto 0 0; display: flex; width: 276px; flex-direction: column; padding: 23px 14px 18px; color: #bec5d1; background: #1d2430; }.brand { display: flex; align-items: center; gap: 11px; padding: 0 8px 35px; color: #fff; font: 800 20px 'Manrope', sans-serif; letter-spacing: -.04em; }.brand-symbol { position: relative; display: grid; width: 30px; height: 30px; place-items: center; border: 1.5px solid #e9edf5; border-radius: 50%; }.brand-symbol::before { width: 10px; height: 10px; content: ''; border: 2px solid #a49aff; border-radius: 50%; }.brand-symbol i { position: absolute; top: -2px; right: -2px; width: 9px; height: 15px; background: #1d2430; border-bottom: 2px solid #e9edf5; transform: rotate(28deg); }
.nav-section-title { margin: 0 0 13px; color: #978bf7; font-size: 11px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; }.nav-section-spaced { margin-top: 29px; }.sidebar-nav { flex: 1; overflow-y: auto; }.sidebar-link { display: flex; align-items: center; gap: 13px; min-height: 44px; margin: 3px 0; padding: 0 12px; color: #bec5d1; font-size: 13px; text-decoration: none; border-radius: 9px; transition: background .2s ease, color .2s ease; }.sidebar-link:hover, .sidebar-link.is-selected { color: #fff; background: #2b3443; }.sidebar-link.is-selected { box-shadow: inset 3px 0 #9a8cff; }.nav-icon { display: inline-grid; width: 18px; place-items: center; color: #8793a5; font-size: 19px; line-height: 1; }.sidebar-link:hover .nav-icon, .sidebar-link.is-selected .nav-icon { color: #c1baff; }.nav-arrow { margin-left: auto; font-size: 21px; line-height: 1; }.sidebar-footer { padding-top: 18px; }.sidebar-help { display: flex; align-items: center; gap: 10px; padding: 13px 10px; border-top: 1px solid #303947; border-bottom: 1px solid #303947; }.help-orb { display: grid; width: 30px; height: 30px; place-items: center; color: #a79cff; border: 1px solid #5d6680; border-radius: 50%; }.sidebar-help strong, .sidebar-help small { display: block; }.sidebar-help strong { color: #eef0f5; font-size: 11px; }.sidebar-help small { margin-top: 3px; color: #8993a4; font-size: 10px; }.sidebar-version { margin-top: 17px; color: #687386; font-size: 9px; letter-spacing: .08em; text-align: center; }.sidebar-version span { color: #9a8cff; }
.main-shell { min-height: 100vh; margin-left: 276px; }.topbar { position: relative; z-index: 10; display: flex; align-items: center; justify-content: space-between; height: 72px; padding: 0 38px; background: #fff; border-bottom: 1px solid #edf0f4; }.page-heading { display: flex; align-items: center; gap: 10px; color: #303744; font: 700 16px 'Manrope', sans-serif; }.page-heading-dot { width: 8px; height: 8px; background: #9a8cff; border-radius: 50%; }.topbar-actions { position: relative; display: flex; align-items: center; gap: 22px; }.notification-button { position: relative; width: 28px; height: 30px; color: #445064; background: transparent; border: 0; cursor: pointer; }.bell { display: inline-block; font-size: 25px; transform: rotate(180deg); }.notification-button b { position: absolute; top: -4px; right: -1px; display: grid; width: 17px; height: 17px; place-items: center; color: #fff; font-size: 10px; background: #ed575f; border: 2px solid #fff; border-radius: 50%; }.profile-button { display: flex; align-items: center; gap: 10px; padding: 0; color: #4a5363; text-align: left; background: transparent; border: 0; cursor: pointer; }.avatar { display: grid; place-items: center; color: #6e4c31; font-weight: 700; background: #f2c696; border-radius: 50%; }.avatar-small { width: 38px; height: 38px; font-size: 11px; border: 3px solid #e7f3ff; }.profile-copy strong, .profile-copy small { display: block; }.profile-copy strong { font-size: 13px; }.profile-copy small { margin-top: 3px; color: #89919f; font-size: 11px; }.profile-chevron { color: #8d96a3; font-size: 16px; }.profile-menu { position: absolute; top: 49px; right: 0; display: grid; min-width: 190px; gap: 5px; padding: 15px; color: #3b4350; background: #fff; border: 1px solid #e8ebf0; border-radius: 10px; box-shadow: 0 12px 25px #24304718; }.profile-menu span { color: #89919f; font-size: 11px; }.profile-menu button { margin-top: 7px; padding: 6px 0; color: #7366dc; text-align: left; background: none; border: 0; cursor: pointer; }.menu-toggle { display: none; width: 34px; height: 34px; padding: 7px 5px; background: #fff; border: 1px solid #e4e8ef; border-radius: 7px; }.menu-toggle span { display: block; height: 2px; margin: 4px 2px; background: #566173; }.app-content { min-height: calc(100vh - 72px); padding: 32px 38px 48px; }.mobile-scrim { display: none; }
@media (max-width: 850px) { .sidebar { width: 245px; transform: translateX(-100%); transition: transform .25s ease; }.sidebar.is-open { transform: translateX(0); }.mobile-scrim { position: fixed; z-index: 15; inset: 0; display: block; background: #11182770; }.main-shell { margin-left: 0; }.topbar { padding: 0 20px; }.menu-toggle { display: block; }.page-heading { margin-right: auto; margin-left: 15px; }.app-content { padding: 25px 20px 40px; } }
@media (max-width: 520px) { .profile-copy, .profile-chevron { display: none; }.topbar-actions { gap: 10px; }.app-content { padding-right: 14px; padding-left: 14px; } }
</style>
