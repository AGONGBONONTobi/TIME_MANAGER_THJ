<!-- src/components/WorkingTimes.vue -->
<template>
  <div class="card p-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h2>📋 Working Times (User {{ userId }})</h2>
      <router-link :to="`/workingTime/${userId}`" class="btn btn-success">
        + Nouveau
      </router-link>
    </div>

    <button class="btn btn-outline-primary mb-3" @click="getWorkingTimes">
      🔄 Rafraîchir
    </button>

    <table class="table table-striped" v-if="workingTimes.length">
      <thead>
        <tr>
          <th>ID</th>
          <th>Début</th>
          <th>Fin</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="wt in workingTimes" :key="wt.id">
          <td>{{ wt.id }}</td>
          <td>{{ wt.start }}</td>
          <td>{{ wt.end || '—' }}</td>
          <td>
            <router-link
              :to="`/workingTime/${userId}/${wt.id}`"
              class="btn btn-sm btn-warning"
            >
              ✏️ Éditer
            </router-link>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else class="text-muted">Aucun working time enregistré.</p>
  </div>
</template>

<script>
import api from '../services/api'

export default {
  name: 'WorkingTimes',
  data() {
    return {
      userId: this.$route.params.userID,
      workingTimes: []
    }
  },
  mounted() {
    this.getWorkingTimes()
  },
  watch: {
    // Si l'ID change dans l'URL, on recharge
    '$route.params.userID'(newId) {
      this.userId = newId
      this.getWorkingTimes()
    }
  },
  methods: {
    async getWorkingTimes() {
      try {
        const res = await api.getWorkingTimes(this.userId)
        this.workingTimes = res.data.data
      } catch (err) {
        console.error(err)
      }
    }
  }
}
</script>
