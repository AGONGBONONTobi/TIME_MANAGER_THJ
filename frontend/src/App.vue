<script>
export default {
  name: 'App',
  data() {
    return {
      currentUserId: 1,
      isNavOpen: false,
      isNavCompact: false,
      isNavPinned: false
    }
  },
  methods: {
    toggleNav() {
      this.isNavOpen = !this.isNavOpen
    },
    closeNav() {
      this.isNavOpen = false
      this.isNavPinned = false
      this.updateCompactState()
    },
    restoreNav() {
      this.isNavCompact = false
      this.isNavPinned = true
      this.isNavOpen = true
    },
    updateCompactState() {
      if (window.scrollY <= 100) {
        this.isNavCompact = false
        this.isNavPinned = false
        return
      }

      if (this.isNavOpen || this.isNavPinned) {
        this.isNavCompact = false
        return
      }

      this.isNavCompact = true
    },
    handleEscape(event) {
      if (event.key === 'Escape') {
        this.closeNav()
      }
    },
    handleScroll() {
      this.updateCompactState()
    }
  },
  mounted() {
    window.addEventListener('keydown', this.handleEscape)
    window.addEventListener('scroll', this.handleScroll, { passive: true })
  },
  beforeUnmount() {
    window.removeEventListener('keydown', this.handleEscape)
    window.removeEventListener('scroll', this.handleScroll)
  }
}
</script>

<template>
  <div class="app-shell">
    <nav
      class="floating-nav"
      :class="{ 'is-compact': isNavCompact, 'is-pinned': isNavPinned }"
      aria-label="Main navigation"
    >
      <router-link class="brand-mark" :to="{ name: 'user' }" @click="closeNav">
        <span class="brand-icon">TM</span>
      </router-link>

      <button
        class="menu-toggle"
        type="button"
        :aria-expanded="isNavOpen"
        aria-controls="main-navigation"
        aria-label="Toggle navigation"
        @click="isNavCompact ? restoreNav() : toggleNav()"
      >
        <span></span>
        <span></span>
        <span></span>
      </button>

      <div id="main-navigation" class="navigation-panel" :class="{ 'is-open': isNavOpen }">
        <div class="nav-links">
          <router-link class="nav-link" :to="{ name: 'user' }" @click="closeNav">
            User
          </router-link>

          <router-link
            class="nav-link"
            :to="{ name: 'workingTimes', params: { userID: currentUserId } }"
            @click="closeNav"
          >
            Working Times
          </router-link>

          <router-link
            class="nav-link"
            :to="{ name: 'clock', params: { userID: currentUserId } }"
            @click="closeNav"
          >
            Clock
          </router-link>

          <router-link
            class="nav-link"
            :to="{ name: 'chartManager', params: { userID: currentUserId } }"
            @click="closeNav"
          >
            Charts
          </router-link>
        </div>
      </div>
    </nav>

    <main class="container app-content">
      <router-view></router-view>
    </main>
  </div>
</template>

<style scoped>
.app-shell {
  min-height: 100vh;
  padding: 1.25rem 1rem 2rem;
  background: #f7f7f5;
}

.floating-nav {
  position: absolute;
  top: 1.25rem;
  left: 50%;
  z-index: 10;
  display: flex;
  align-items: center;
  gap: 2rem;
  width: min(100%, 980px);
  min-height: 64px;
  margin: 0 auto;
  padding: 0.5rem 0.65rem 0.5rem 1.1rem;
  color: #1d1d1b;
  background: rgba(255, 255, 255, 0.94);
  transform: translateX(-50%);
  border: 1px solid rgba(25, 25, 22, 0.06);
  border-radius: 999px;
  box-shadow: 0 12px 28px rgba(37, 33, 27, 0.13), 0 2px 6px rgba(37, 33, 27, 0.06);
  transition: width 0.6s ease, min-height 0.6s ease, padding 0.6s ease, box-shadow 0.6s ease;
}

.brand-mark {
  position: absolute;
  left: 1.1rem;
  display: inline-flex;
  align-items: center;
  gap: 0.7rem;
  color: inherit;
  font-size: 0.95rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  text-decoration: none;
}

.brand-icon {
  display: grid;
  width: 38px;
  height: 38px;
  place-items: center;
  color: #fff;
  font-size: 0.68rem;
  letter-spacing: 0.08em;
  background: #252522;
  border-radius: 50%;
}

.navigation-panel {
  display: flex;
  width: 100%;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.nav-link {
  position: relative;
  padding: 0.65rem 0.85rem;
  color: #252522;
  font-size: 0.9rem;
  font-weight: 600;
  text-decoration: none;
  transition: color 0.5s ease;
}

.nav-link::after {
  position: absolute;
  right: 0.85rem;
  bottom: 0.25rem;
  left: 0.85rem;
  height: 2px;
  content: '';
  background: #252522;
  transform: scaleX(0);
  transition: transform 0.5s ease;
}

.nav-link:hover,
.nav-link.router-link-active {
  color: #8a5a35;
}

.nav-link.router-link-active::after {
  transform: scaleX(1);
}

.menu-toggle {
  display: none;
  flex: 0 0 auto;
  width: 48px;
  height: 48px;
  padding: 0;
  background: #fff;
  border: 1px solid rgba(25, 25, 22, 0.08);
  border-radius: 50%;
  box-shadow: 0 4px 12px rgba(37, 33, 27, 0.1);
}

.floating-nav.is-compact {
  position: fixed;
  top: 1rem;
  width: 56px;
  min-height: 56px;
  padding: 4px;
  transform: translateX(-50%);
}

.floating-nav.is-pinned {
  position: fixed;
  top: 1rem;
}

.floating-nav.is-compact .brand-mark,
.floating-nav.is-compact .navigation-panel {
  display: none;
}

.floating-nav.is-compact .menu-toggle {
  display: block;
  margin: 0;
}

.menu-toggle span {
  display: block;
  width: 18px;
  height: 2px;
  margin: 4px auto;
  background: #252522;
  border-radius: 2px;
  transition: transform 0.2s ease, opacity 0.2s ease;
}

.menu-toggle[aria-expanded='true'] span:nth-child(1) {
  transform: translateY(6px) rotate(45deg);
}

.menu-toggle[aria-expanded='true'] span:nth-child(2) {
  opacity: 0;
}

.menu-toggle[aria-expanded='true'] span:nth-child(3) {
  transform: translateY(-6px) rotate(-45deg);
}

.app-content {
  padding-top: 7rem;
}

@media (max-width: 768px) {
  .app-shell {
    padding: 0.7rem 0.7rem 1.5rem;
  }

  .floating-nav {
    min-height: 58px;
    padding: 0.3rem 0.45rem 0.3rem 0.75rem;
  }

  .floating-nav.is-compact {
    top: 0.7rem;
  }

  .brand-icon {
    width: 38px;
    height: 38px;
  }

  .menu-toggle {
    display: block;
    margin-left: auto;
  }

  .navigation-panel {
    position: absolute;
    top: calc(100% + 0.7rem);
    right: 0;
    left: 0;
    display: block;
    padding: 0.7rem;
    visibility: hidden;
    background: rgba(255, 255, 255, 0.98);
    border: 1px solid rgba(25, 25, 22, 0.07);
    border-radius: 24px;
    box-shadow: 0 16px 35px rgba(37, 33, 27, 0.15);
    opacity: 0;
    transform: translateY(-8px);
    transition: opacity 0.6s ease, transform 0.6s ease, visibility 0.6s ease;
  }

  .floating-nav.is-compact .navigation-panel {
    display: none;
  }

  .navigation-panel.is-open {
    visibility: visible;
    opacity: 1;
    transform: translateY(0);
  }

  .nav-links {
    display: grid;
    gap: 0.2rem;
  }

  .nav-link {
    padding: 0.85rem 1rem;
    border-radius: 14px;
  }

  .nav-link:hover,
  .nav-link.router-link-active {
    background: #f5ede5;
  }

  .nav-link::after {
    display: none;
  }

  .app-content {
    padding-top: 5rem;
  }
}

@media (prefers-reduced-motion: reduce) {
  .nav-link,
  .nav-link::after,
  .menu-toggle span,
  .navigation-panel {
    transition: none;
  }

  .floating-nav {
    transition: none;
  }
}
</style>
