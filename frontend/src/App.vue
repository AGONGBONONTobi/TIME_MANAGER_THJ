<script>
import api from './services/api'
import { clearAuthUser, readAuthUser, writeAuthUser } from './utils/auth'

export default {
  name: 'App',
  data() {
    return {
      isNavOpen: false,
      isProfileOpen: false,
      isHelpOpen: false,
      isDarkMode: localStorage.getItem('darkMode') === 'true',
      currentUser: readAuthUser(),
      lastDashboard: 'dashboard'
    }
  },
  computed: {
    currentUserId() {
      return this.currentUser ? Number(this.currentUser.id) : null
    },
    isAuthenticated() {
      return Boolean(this.currentUser && this.currentUser.id && this.currentUser.role)
    },
    userInitials() {
      const username = this.currentUser?.username || 'U'
      const names = username.trim().split(/\s+/).filter(Boolean)
      if (!names.length) return 'U'
      return names.slice(0, 2).map((name) => name[0].toUpperCase()).join('')
    },
    userRoleLabel() {
      if (!this.currentUser?.role) return 'Utilisateur'
      return String(this.currentUser.role).charAt(0).toUpperCase() + String(this.currentUser.role).slice(1)
    },
    dashboardTarget() {
      if (!this.isAuthenticated) return { path: '/sign_in' }
      if (this.currentUser.role === 'admin') return { path: '/admin' }
      if (this.currentUser.role === 'manager') return { path: '/manager' }
      return { path: '/employee' }
    },
    canViewManager() {
      return ['manager', 'admin'].includes(String(this.currentUser?.role || '').toLowerCase())
    },
    canViewAdmin() {
      return String(this.currentUser?.role || '').toLowerCase() === 'admin'
    },
    isAuthLayout() {
      return this.$route.meta?.guestOnly === true
    }
  },
  watch: {
    '$route'(route) {
      this.currentUser = readAuthUser()
      if (route.path === '/manager') this.lastDashboard = 'manager'
      else if (route.path === '/admin') this.lastDashboard = 'admin'
      else if (route.path === '/employee') this.lastDashboard = 'employee'
      else if (route.path === '/dashboard') this.lastDashboard = 'dashboard'
    }
  },
  methods: {
    closeNav() { this.isNavOpen = false },
    toggleNav() { this.isNavOpen = !this.isNavOpen },
    toggleHelp() { this.isHelpOpen = !this.isHelpOpen },
    toggleDarkMode() {
      this.isDarkMode = !this.isDarkMode;
      localStorage.setItem('darkMode', this.isDarkMode);
      if (this.isDarkMode) {
        document.documentElement.classList.add('theme-dark');
      } else {
        document.documentElement.classList.remove('theme-dark');
      }
    },
    async signOut() {
      try {
        await api.post('/auth/sign_out')
      } catch (error) {
        console.warn('Déconnexion backend impossible, nettoyage local effectué.', error)
      } finally {
        clearAuthUser()
        this.currentUser = null
        this.isProfileOpen = false
        this.$router.push('/sign_in')
      }
    },
    async refreshCurrentUser() {
      if (!this.currentUser) return

      try {
        const response = await api.getCurrentUser()
        const user = response.data?.user
        this.currentUser = writeAuthUser(user)
      } catch (error) {
        if (error?.response?.status === 401) {
          clearAuthUser()
          this.currentUser = null
        }
      }
    },
    handleEscape(event) {
      if (event.key === 'Escape') {
        this.isNavOpen = false
        this.isProfileOpen = false
        this.isHelpOpen = false
      }
    }
  },
  mounted() {
    window.addEventListener('keydown', this.handleEscape)
    if (this.isDarkMode) {
      document.documentElement.classList.add('theme-dark');
    }
    this.refreshCurrentUser()
    if (this.$route.path === '/manager') this.lastDashboard = 'manager'
    else if (this.$route.path === '/admin') this.lastDashboard = 'admin'
    else if (this.$route.path === '/employee') this.lastDashboard = 'employee'
  },
  beforeUnmount() { window.removeEventListener('keydown', this.handleEscape) }
}
</script>

<template>
  <div v-if="isAuthLayout" class="auth-shell">
    <router-view />
  </div>

  <div v-else class="app-shell">
    <a class="skip-link" href="#main-content">Aller au contenu principal</a>
    <div v-if="isNavOpen" class="mobile-scrim" aria-hidden="true" @click="closeNav"></div>
    <aside class="sidebar" :class="{ 'is-open': isNavOpen }">
      <div class="brand"><span class="brand-symbol" aria-hidden="true"><i></i></span><span>Time Manager</span></div>
      <nav class="sidebar-nav" aria-label="Navigation principale">
        <p class="nav-section-title">Navigation</p>
        <router-link v-if="isAuthenticated" class="sidebar-link" :class="{ 'is-selected': $route.path.startsWith('/dashboard') || $route.path === '/employee' || $route.path === '/manager' || $route.path === '/admin' }" :to="dashboardTarget" @click="closeNav"><span class="nav-icon" aria-hidden="true">⌂</span><span>Tableau de bord</span><span class="nav-arrow" aria-hidden="true">›</span></router-link>
        <p v-if="isAuthenticated" class="nav-section-title nav-section-spaced">Mon espace</p>
        <router-link v-if="isAuthenticated" class="sidebar-link" :to="{ name: 'workingTimes', params: { userID: currentUserId } }" @click="closeNav"><span class="nav-icon" aria-hidden="true">◷</span><span>Historique</span><span class="nav-arrow" aria-hidden="true">›</span></router-link>
        <router-link v-if="isAuthenticated" class="sidebar-link" :to="{ name: 'clock', params: { userID: currentUserId } }" @click="closeNav"><span class="nav-icon" aria-hidden="true">◉</span><span>Pointage</span><span class="nav-arrow" aria-hidden="true">›</span></router-link>
        <router-link v-if="isAuthenticated" class="sidebar-link" :to="{ name: 'chartManager', params: { userID: currentUserId } }" @click="closeNav"><span class="nav-icon" aria-hidden="true">▥</span><span>Graphiques</span><span class="nav-arrow" aria-hidden="true">›</span></router-link>
        <router-link v-if="canViewManager" class="sidebar-link" to="/manager" @click="closeNav"><span class="nav-icon" aria-hidden="true">◫</span><span>Espace manager</span><span class="nav-arrow" aria-hidden="true">›</span></router-link>
        <router-link v-if="canViewAdmin" class="sidebar-link" to="/admin" @click="closeNav"><span class="nav-icon" aria-hidden="true">⚑</span><span>Espace admin</span><span class="nav-arrow" aria-hidden="true">›</span></router-link>
      </nav>
      <div class="sidebar-footer"><button class="sidebar-help" type="button" @click="toggleHelp"><span class="help-orb" aria-hidden="true">?</span><span><strong>Besoin d'aide ?</strong><small>Ouvrir le centre d'aide</small></span></button><div class="sidebar-version">TIME MANAGER <span>v1.0</span></div></div>
    </aside>
    <div class="main-shell">
      <header class="topbar">
        <button class="menu-toggle" type="button" aria-label="Ouvrir la navigation" :aria-expanded="isNavOpen" @click="toggleNav"><span></span><span></span><span></span></button>
        <div class="page-heading"><span class="page-heading-dot"></span><span>{{ isAuthenticated ? 'Mon espace' : 'Connexion' }}</span></div>
        <div class="topbar-actions">
          <button class="theme-toggle" type="button" aria-label="Basculer le thème" @click="toggleDarkMode">
            <span aria-hidden="true">{{ isDarkMode ? '☀️' : '🌙' }}</span>
          </button>
          <button v-if="isAuthenticated" class="profile-button" type="button" :aria-expanded="isProfileOpen" aria-controls="profile-menu" @click="isProfileOpen = !isProfileOpen"><span class="avatar avatar-small" aria-hidden="true">{{ userInitials }}</span><span class="profile-copy"><strong>{{ currentUser.username || 'Utilisateur' }}</strong><small>{{ userRoleLabel }}</small></span><span class="profile-chevron" aria-hidden="true">⌄</span></button>
          <router-link v-else class="signin-link" to="/sign_in">Connexion</router-link>
          <div v-if="isProfileOpen" id="profile-menu" class="profile-menu"><strong>{{ currentUser.username || 'Utilisateur' }}</strong><span>{{ userRoleLabel }}</span><button type="button" @click="signOut">Déconnexion</button></div>
        </div>
      </header>
      <main id="main-content" class="app-content" tabindex="-1"><router-view /></main>
    </div>
    <div v-if="isHelpOpen" class="help-backdrop" @click.self="toggleHelp">
      <section class="help-dialog" role="dialog" aria-modal="true" aria-labelledby="help-title">
        <button class="help-close" type="button" aria-label="Fermer le centre d'aide" @click="toggleHelp">×</button>
        <p class="help-kicker">CENTRE D'AIDE</p>
        <h2 id="help-title">Pointez sans ordinateur</h2>
        <p>Depuis un téléphone, ouvrez <strong>Pointage</strong>, puis utilisez le bouton Clock In au début de votre service et Clock Out à la fin.</p>
        <div class="help-steps"><strong>Besoin d'accompagnement ?</strong><span>Demandez une démonstration à votre manager ou consultez la note interne de votre équipe.</span></div>
        <button class="help-action" type="button" @click="toggleHelp">J'ai compris</button>
      </section>
    </div>
  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@600;700;800&display=swap');
:root { font-family: 'DM Sans', sans-serif; color: #20242e; background: #f7f8fb; font-synthesis: none; }
* { box-sizing: border-box; } body { min-width: 320px; margin: 0; } button, input { font: inherit; }
.auth-shell { min-height: 100vh; }
.app-shell { min-height: 100vh; background: #f7f8fb; }.sidebar { position: fixed; z-index: 20; inset: 0 auto 0 0; display: flex; width: 276px; flex-direction: column; padding: 23px 14px 18px; color: #bec5d1; background: #1d2430; }.brand { display: flex; align-items: center; gap: 11px; padding: 0 8px 35px; color: #fff; font: 800 20px 'Manrope', sans-serif; letter-spacing: -.04em; }.brand-symbol { position: relative; display: grid; width: 30px; height: 30px; place-items: center; border: 1.5px solid #e9edf5; border-radius: 50%; }.brand-symbol::before { width: 10px; height: 10px; content: ''; border: 2px solid #a49aff; border-radius: 50%; }.brand-symbol i { position: absolute; top: -2px; right: -2px; width: 9px; height: 15px; background: #1d2430; border-bottom: 2px solid #e9edf5; transform: rotate(28deg); }
.nav-section-title { margin: 0 0 13px; color: #978bf7; font-size: 11px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; }.nav-section-spaced { margin-top: 29px; }.sidebar-nav { flex: 1; overflow-y: auto; }.sidebar-link { display: flex; align-items: center; gap: 13px; min-height: 44px; margin: 3px 0; padding: 0 12px; color: #bec5d1; font-size: 13px; text-decoration: none; border-radius: 9px; transition: background .2s ease, color .2s ease; }.sidebar-link:hover, .sidebar-link.is-selected { color: #fff; background: #2b3443; }.sidebar-link.is-selected { box-shadow: inset 3px 0 #9a8cff; }.nav-icon { display: inline-grid; width: 18px; place-items: center; color: #8793a5; font-size: 19px; line-height: 1; }.sidebar-link:hover .nav-icon, .sidebar-link.is-selected .nav-icon { color: #c1baff; }.nav-arrow { margin-left: auto; font-size: 21px; line-height: 1; }.sidebar-footer { padding-top: 18px; }.sidebar-help { display: flex; align-items: center; gap: 10px; padding: 13px 10px; border-top: 1px solid #303947; border-bottom: 1px solid #303947; }.help-orb { display: grid; width: 30px; height: 30px; place-items: center; color: #a79cff; border: 1px solid #5d6680; border-radius: 50%; }.sidebar-help strong, .sidebar-help small { display: block; }.sidebar-help strong { color: #eef0f5; font-size: 11px; }.sidebar-help small { margin-top: 3px; color: #8993a4; font-size: 10px; }.sidebar-version { margin-top: 17px; color: #687386; font-size: 9px; letter-spacing: .08em; text-align: center; }.sidebar-version span { color: #9a8cff; }
.main-shell { min-height: 100vh; margin-left: 276px; }.topbar { position: relative; z-index: 10; display: flex; align-items: center; justify-content: space-between; height: 72px; padding: 0 38px; background: #1e5a8a; border-bottom: 1px solid #15466b; }.page-heading { display: flex; align-items: center; gap: 10px; color: #fff; font: 700 16px 'Manrope', sans-serif; }.page-heading-dot { width: 8px; height: 8px; background: #9a8cff; border-radius: 50%; }.topbar-actions { position: relative; display: flex; align-items: center; gap: 22px; }.notification-button { position: relative; width: 28px; height: 30px; color: #fff; background: transparent; border: 0; cursor: pointer; }.bell { display: inline-block; font-size: 25px; transform: rotate(180deg); }.notification-button b { position: absolute; top: -4px; right: -1px; display: grid; width: 17px; height: 17px; place-items: center; color: #fff; font-size: 10px; background: #ed575f; border: 2px solid #fff; border-radius: 50%; }.profile-button { display: flex; align-items: center; gap: 10px; padding: 0; color: #fff; text-align: left; background: transparent; border: 0; cursor: pointer; }.avatar { display: grid; place-items: center; color: #6e4c31; font-weight: 700; background: #f2c696; border-radius: 50%; }.avatar-small { width: 38px; height: 38px; font-size: 11px; border: 3px solid #e7f3ff; }.profile-copy strong, .profile-copy small { display: block; }.profile-copy strong { font-size: 13px; }.profile-copy small { margin-top: 3px; color: #d0e4f5; font-size: 11px; }.profile-chevron { color: #d0e4f5; font-size: 16px; }.profile-menu { position: absolute; top: 49px; right: 0; display: grid; min-width: 190px; gap: 5px; padding: 15px; color: #3b4350; background: #fff; border: 1px solid #e8ebf0; border-radius: 10px; box-shadow: 0 12px 25px #24304718; }.profile-menu span { color: #89919f; font-size: 11px; }.profile-menu button { margin-top: 7px; padding: 6px 0; color: #7366dc; text-align: left; background: none; border: 0; cursor: pointer; }.menu-toggle { display: none; width: 34px; height: 34px; padding: 7px 5px; background: #1e5a8a; border: 1px solid #15466b; border-radius: 7px; }.menu-toggle span { display: block; height: 2px; margin: 4px 2px; background: #fff; }.app-content { min-height: calc(100vh - 72px); padding: 32px 38px 48px; }.mobile-scrim { display: none; }
@media (max-width: 850px) { .sidebar { width: 245px; transform: translateX(-100%); transition: transform .25s ease; }.sidebar.is-open { transform: translateX(0); }.mobile-scrim { position: fixed; z-index: 15; inset: 0; display: block; background: #11182770; }.main-shell { margin-left: 0; }.topbar { padding: 0 20px; }.menu-toggle { display: block; }.page-heading { margin-right: auto; margin-left: 15px; }.app-content { padding: 25px 20px 40px; } }
@media (max-width: 520px) { .profile-copy, .profile-chevron { display: none; }.topbar-actions { gap: 10px; }.app-content { padding-right: 14px; padding-left: 14px; } }
.skip-link { position: fixed; z-index: 100; top: -100px; left: 16px; padding: 10px 14px; color: #fff; background: #1d2430; border-radius: 7px; }.skip-link:focus { top: 16px; }

.theme-toggle { background: transparent; border: none; font-size: 20px; cursor: pointer; padding: 5px; }
.theme-dark body, .theme-dark .app-shell, .theme-dark .auth-shell { background: #111827 !important; color: #f3f4f6 !important; }
.theme-dark .topbar { background: #1f2937 !important; border-bottom-color: #374151 !important; }
.theme-dark .page-heading { color: #f3f4f6 !important; }
.theme-dark .profile-menu { background: #1f2937 !important; border-color: #374151 !important; color: #f3f4f6 !important; box-shadow: 0 12px 25px #00000080 !important; }
.theme-dark .profile-menu span { color: #9ca3af !important; }
.theme-dark .help-dialog { background: #1f2937 !important; color: #f3f4f6 !important; box-shadow: 0 20px 60px #00000080 !important; }
.theme-dark .help-dialog h2 { color: #f3f4f6 !important; }
.theme-dark .help-dialog p:not(.help-kicker) { color: #9ca3af !important; }
.theme-dark .help-steps { background: #374151 !important; border-left-color: #a78bfa !important; color: #d1d5db !important; }
.theme-dark .help-steps span { color: #9ca3af !important; }
.theme-dark .app-content { background: #111827 !important; color: #f3f4f6 !important; }
/* Cards, panels and tables in dark mode */
.theme-dark .card, .theme-dark [class*="card"], .theme-dark [class*="panel"], .theme-dark [class*="box"] { background: #1f2937 !important; border-color: #374151 !important; color: #f3f4f6 !important; }
.theme-dark table { background: #1f2937 !important; color: #f3f4f6 !important; }
.theme-dark th { background: #374151 !important; color: #d1d5db !important; border-color: #4b5563 !important; }
.theme-dark td { border-color: #374151 !important; color: #e5e7eb !important; }
.theme-dark input, .theme-dark select, .theme-dark textarea { background: #374151 !important; color: #f3f4f6 !important; border-color: #4b5563 !important; }
.theme-dark input::placeholder { color: #9ca3af !important; }
.theme-dark label { color: #d1d5db !important; }
.theme-dark h1, .theme-dark h2, .theme-dark h3, .theme-dark h4 { color: #f9fafb !important; }
/* Fix focus ring for dark mode backgrounds */
.theme-dark .sidebar-link:focus-visible,
.theme-dark .profile-button:focus-visible,
.theme-dark .menu-toggle:focus-visible,
.theme-dark button:focus-visible,
.theme-dark a:focus-visible,
.theme-dark input:focus-visible { outline-color: #a78bfa !important; }


.sidebar-link:focus-visible, .profile-button:focus-visible, .menu-toggle:focus-visible, .sidebar-help:focus-visible, button:focus-visible, a:focus-visible, input:focus-visible { outline: 3px solid #000; outline-offset: 3px; }
.sidebar-help { width: 100%; color: inherit; text-align: left; background: transparent; border-right: 0; border-left: 0; cursor: pointer; }
.help-backdrop { position: fixed; z-index: 50; inset: 0; display: grid; place-items: center; padding: 20px; background: #11182799; }.help-dialog { position: relative; width: min(100%, 430px); padding: 28px; color: #293140; background: #fff; border-radius: 14px; box-shadow: 0 20px 60px #11182740; }.help-close { position: absolute; top: 12px; right: 14px; width: 36px; height: 36px; color: #5d6675; background: transparent; border: 0; font-size: 24px; cursor: pointer; }.help-kicker { margin: 0 0 8px; color: #786be7; font-size: 10px; font-weight: 800; letter-spacing: .12em; }.help-dialog h2 { margin: 0; font: 800 25px 'Manrope', sans-serif; }.help-dialog p:not(.help-kicker) { color: #5d6675; line-height: 1.6; }.help-steps { display: grid; gap: 5px; margin: 18px 0; padding: 13px; background: #f5f3ff; border-left: 3px solid #786be7; font-size: 12px; line-height: 1.5; }.help-steps span { color: #6d7480; }.help-action { min-height: 44px; padding: 0 16px; color: #fff; background: #786be7; border: 0; border-radius: 7px; font-weight: 700; cursor: pointer; }.app-content:focus { outline: none; }
@media (prefers-reduced-motion: reduce) { *, *::before, *::after { scroll-behavior: auto !important; transition-duration: .01ms !important; animation-duration: .01ms !important; animation-iteration-count: 1 !important; } }

/* Premium navigation treatment: quiet surfaces, deliberate hierarchy, generous rhythm. */
.sidebar {
  width: 292px !important;
  padding: 20px 16px 16px !important;
  background: #102a43 !important;
  border-right: 1px solid #1d4f78;
  box-shadow: 14px 0 38px rgba(10, 35, 58, .18);
}
.main-shell { margin-left: 292px !important; }
.brand {
  min-height: 58px;
  margin-bottom: 22px;
  padding: 0 10px 22px !important;
  border-bottom: 1px solid #2d5f87;
  font-size: 18px !important;
  letter-spacing: -.045em !important;
  color: #fff !important;
}
.brand-symbol {
  width: 34px !important;
  height: 34px !important;
  background: #102a43;
  border: 0 !important;
}
.brand-symbol::before { border-color: #b9dcff !important; }
.brand-symbol i { background: #102a43 !important; border-color: #b9dcff !important; }
.nav-section-title {
  margin: 0 10px 9px !important;
  color: #8fb5d6 !important;
  font-size: 9px !important;
  letter-spacing: .16em !important;
  color: #8fb5d6 !important;
}
.nav-section-spaced { margin-top: 26px !important; }
.sidebar-link {
  position: relative;
  min-height: 46px !important;
  margin: 3px 0 !important;
  padding: 0 12px !important;
  border: 1px solid transparent;
  border-radius: 8px !important;
  color: #d8e9f7 !important;
  font-size: 12px !important;
  font-weight: 600;
  letter-spacing: .005em;
}
.sidebar-link:hover { color: #fff !important; background: #1b456b !important; border-color: #2d6b99; }
.sidebar-link.is-selected {
  color: #fff !important;
  background: #1e5a8a !important;
  border-color: #63b3ed;
  box-shadow: inset 3px 0 #9bd3ff !important;
}
.nav-icon {
  width: 24px !important;
  color: #8fb5d6 !important;
  font-size: 17px !important;
}
.sidebar-link:hover .nav-icon { color: #d8efff !important; }
.sidebar-link.is-selected .nav-icon { color: #fff !important; }
.nav-arrow { color: #8fb5d6; font-size: 19px !important; }
.sidebar-link.is-selected .nav-arrow { color: #b9dcff; }
.sidebar-footer { padding: 16px 0 0 !important; border-top: 1px solid #2d5f87; }
.sidebar-help {
  padding: 12px 10px !important;
  border: 0 !important;
  border-radius: 8px;
}
.sidebar-help:hover { background: #1b456b; }
.help-orb { width: 28px !important; height: 28px !important; color: #b9dcff !important; border-color: #76a9cc !important; }
.sidebar-help strong { color: #fff !important; }
.sidebar-help small, .sidebar-version { color: #8fb5d6 !important; }
.sidebar-version span { color: #b9dcff !important; }

@media (max-width: 850px) {
  .sidebar { width: 270px !important; }
  .main-shell { margin-left: 0 !important; }
}

/* Keep page rhythm consistent: broad analysis pages, comfortable operational pages. */
.app-content > .dashboard-page,
.app-content > .charts-page,
.app-content > .timeline-page {
  width: min(100%, 1120px) !important;
  margin-right: auto !important;
  margin-left: auto !important;
}
.app-content > .clock-page,
.app-content > .working-time-page {
  width: min(100%, 1120px) !important;
  margin-right: auto !important;
  margin-left: auto !important;
}
.app-content .timeline-page,
.app-content .clock-page,
.app-content .working-time-page {
  width: min(100%, 1120px) !important;
}
@media (max-width: 700px) {
  .app-content > .dashboard-page,
  .app-content > .charts-page,
  .app-content > .clock-page,
  .app-content > .working-time-page,
  .app-content > .timeline-page {
    width: 100% !important;
  }
}
</style>
