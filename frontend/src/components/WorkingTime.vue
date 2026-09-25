<script>
import api from '../services/api'

export default {
  name: 'WorkingTime',
  props: ['userID', 'workingTimeID'],
  data() {
    return {
      workingTime: null,
      start_at: '',
      end_at: ''
    }
  },
  methods: {
    toUtcIso(localDateTime) {
      if (!localDateTime) return null
      return new Date(localDateTime).toISOString()
    },

    async createWorkingTime() {
      if (!this.userID) return alert('Aucun user !')
      try {
        const res = await api.post(`/workingtime/${this.userID}`, {
          start_at: this.toUtcIso(this.start_at),
          end_at: this.toUtcIso(this.end_at)
        })
        this.workingTime = res.data.data
        this.start_at = this.workingTime.start_at
        this.end_at = this.workingTime.end_at
        alert('WorkingTime créé !')
      } catch (err) {
        console.error(err)
        alert('Erreur lors de la création')
      }
    },

    async updateWorkingTime() {
      if (!this.workingTimeID) return alert('Aucun workingtime à mettre à jour')
      try {
        const res = await api.put(`/workingtime/${this.workingTimeID}`, {
          start_at: this.toUtcIso(this.start_at),
          end_at: this.toUtcIso(this.end_at)
        })
        this.workingTime = res.data.data
        this.start_at = this.workingTime.start_at
        this.end_at = this.workingTime.end_at
        alert(`WorkingTime ${this.workingTimeID} mis à jour`)
      } catch (err) {
        console.error(err)
      }
    },

    async deleteWorkingTime() {
      if (!this.workingTimeID) return alert('Aucun workingtime à supprimer')
      if (!confirm('Confirmer la suppression ?')) return
      try {
        await api.delete(`/workingtime/${this.workingTimeID}`)
        this.workingTime = null
        this.start_at = ''
        this.end_at = ''
        alert('WorkingTime supprimé')
      } catch (err) {
        console.error(err)
      }
    }
  }
}
</script>

<template>
  <div class="card p-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h2>
        {{ isEdit ? '✏️ Éditer Working Time' : '➕ Nouveau Working Time' }}
        <small class="text-muted">(User {{ userID }})</small>
      </h2>
      <router-link :to="`/workingTimes/${userID}`" class="btn btn-outline-secondary">
        ← Retour
      </router-link>
    </div>

    <div class="mb-3">
      <label class="form-label">Début</label>
      <input v-model="start_at" type="datetime-local" class="form-control" />
    </div>
    <div class="mb-3">
      <label class="form-label">Fin</label>
      <input v-model="end_at" type="datetime-local" class="form-control" />
    </div>

    <div class="d-flex gap-2">
      <button
        v-if="!isEdit"
        class="btn btn-success"
        @click="createWorkingTime"
      >
        Créer
      </button>
      <button
        v-else
        class="btn btn-warning"
        @click="updateWorkingTime"
      >
        Mettre à jour
      </button>
      <button
        v-if="isEdit"
        class="btn btn-danger"
        @click="deleteWorkingTime"
      >
        Supprimer
      </button>
    </div>

    <div v-if="workingTime" class="alert alert-info mt-3">
      <strong>WorkingTime #{{ workingTime.id }} :</strong>
      {{ formatTime(workingTime.start_at) }} → {{ formatTime(workingTime.end_at) }}
    </div>
  </div>
</template>


<style scoped>

</style>
