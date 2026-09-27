<!-- src/components/WorkingTime.vue -->
<template>
  <div class="card p-4">
    <h2>⏱️ Gestion du temps de travail</h2>

    <div class="mb-3">
      <label class="form-label">Début</label>
      <input v-model="start_at" type="datetime-local" class="form-control" />
    </div>
    <div class="mb-3">
      <label class="form-label">Fin</label>
      <input v-model="end_at" type="datetime-local" class="form-control" />
    </div>

    <div class="d-flex gap-2">
      <button class="btn btn-success" @click="createWorkingTime">Créer</button>
      <button class="btn btn-warning" @click="updateWorkingTime">Mettre à jour</button>
      <button class="btn btn-danger" @click="deleteWorkingTime">Supprimer</button>
    </div>

    <div v-if="workingTime" class="alert alert-info mt-3">
      <strong>WorkingTime actuel :</strong>
      {{ workingTime.start_at }} → {{ workingTime.end_at }}
      (ID: {{ workingTime.id }})
    </div>
  </div>
</template>

<script>
import api from '../services/api'

export default {
  name: 'WorkingTime',
  data() {
    return {
      workingTime: null,
      start_at: '',
      end_at: ''
    }
  },
  methods: {
    async createWorkingTime() {
      const id = this.$route.params.userID || this.user?.id
      if (!id) return alert('Aucun user fourni')
      try {
        const res = await api.post(`/workingtime/${id}`, {
          start_at: this.start_at,
          end_at: this.end_at
        })
        this.workingTime = res.data.data
        this.start_at = this.workingTime.start_at
        this.end_at = this.workingTime.end_at
        alert('Temps de travail créé !')
      } catch (err) {
        console.error(err)
        alert('Erreur lors de la création')
      }
    },

    async updateWorkingTime() {
      const id = this.$route.params.workingTimeId || this.workingTime?.id
      if (!id) return alert('Aucun temps de travail à mettre à jour')
      try {
        const res = await api.put(`/workingtime/${id}`, {
          start_at: this.start_at,
          end_at: this.end_at
        })
        this.workingTime = res.data.data
        alert('Temps de travail mis à jour !')
      } catch (err) {
        console.error(err)
      }
    },

    async deleteWorkingTime() {
      const id = this.$route.params.workingTimeId || this.workingTime?.id
      if (!id) return alert('Aucun temps de travail à supprimer')
      if (!confirm('Confirmer la suppression ?')) return
      try {
        await api.delete(`/workingtime/${id}`)
        this.workingTime = null
        this.start_at = ''
        this.end_at = ''
        alert('Temps de travail supprimé !')
      } catch (err) {
        console.error(err)
      }
    }
  }
}
</script>

<style scoped>
</style>
