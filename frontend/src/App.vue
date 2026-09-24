<script>
export default {
  name: 'App',
  data() {
    return {
      currentUserId: 1,
      isNavOpen: false
    }
  },
  methods: {
    toggleNav() {
      this.isNavOpen = !this.isNavOpen
    }
  }
}
</script>

<template>
  <div>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-sm">
      <div class="container-fluid">

        <router-link class="navbar-brand fw-bold" :to="{ name: 'user' }">
          ⏱️ Time Manager
        </router-link>

        <button
          class="navbar-toggler"
          type="button"
          @click="toggleNav"
          aria-label="Toggle navigation"
        >
          <span class="navbar-toggler-icon"></span>
        </button>

        <!-- Liens de navigation -->
        <div class="collapse navbar-collapse" :class="{ show: isNavOpen }">
          <ul class="navbar-nav me-auto mb-2 mb-lg-0">

            <li class="nav-item">
              <router-link
                class="nav-link"
                :to="{ name: 'user' }"
              >
                👤 User
              </router-link>
            </li>

            <li class="nav-item">
              <router-link
                class="nav-link"
                :to="{ name: 'workingTimes', params: { userID: currentUserId } }"
              >
                📋 Working Times
              </router-link>
            </li>

            <li class="nav-item">
              <router-link
                class="nav-link"
                :to="{ name: 'clockManager', params: { userID: currentUserId } }"
              >
                ⏰ Clock
              </router-link>
            </li>

            <li class="nav-item">
              <router-link
                class="nav-link"
                :to="{ name: 'chartManager', params: { userID: currentUserId } }"
              >
                📊 Charts
              </router-link>
            </li>

          </ul>

          <!-- Badge User ID à droite -->
          <span class="navbar-text text-white">
            <span class="badge bg-primary">
              User ID: {{ currentUserId }}
            </span>
          </span>
        </div>
      </div>
    </nav>
    
    <main class="container my-4">
      <router-view></router-view>
    </main>
  </div>
</template>

<style scoped>
.navbar-brand {
  font-size: 1.3rem;
}

.nav-link {
  font-weight: 500;
  transition: color 0.2s;
}

.nav-link:hover {
  color: #60a5fa !important;
}

/* Lien actif — Bootstrap ajoute automatiquement "router-link-active" */
.nav-link.router-link-active {
  color: #60a5fa !important;
  border-bottom: 2px solid #60a5fa;
}

.navbar-text {
  font-size: 0.9rem;
}
</style>
