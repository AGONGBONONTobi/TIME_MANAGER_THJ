<!-- src/components/User.vue -->
<template>
  <div class="card p-4">
    <h2>👤 Gestion de l'utilisateur</h2>

    <div class="mb-3">
      <label class="form-label">Nom d'utilisateur</label>
      <input v-model="username" class="form-control" placeholder="Entrez un nom" />
    </div>
    <div class="mb-3">
      <label class="form-label">Email</label>
      <input v-model="email" type="email" class="form-control" placeholder="Entrez un email" />
    </div>

    <div class="d-flex gap-2">
      <button class="btn btn-success" @click="createUser">Créer</button>
      <button class="btn btn-primary" @click="getUser">Récupérer</button>
      <button class="btn btn-warning" @click="updateUser">Mettre à jour</button>
      <button class="btn btn-danger" @click="deleteUser">Supprimer</button>
    </div>

    <div v-if="user" class="alert alert-info mt-3">
      <strong>User actuel :</strong> {{ user.username }} (ID: {{ user.id }})
    </div>
  </div>
</template>

<script>
import api from '../services/api'

export default {
  name: 'User',
  data() {
    return {
      user: null,
      username: '',
      email: ''
    }
  },
  mounted() {
    if (this.$route.params.userID) {
      this.getUser()
    }
  },
  methods: {
    async createUser() {
      try {
        const res = await api.post('/users', {
          user: {
            username: this.username,
            email: this.email
          }
        })
        this.user = res.data.data
        this.username = this.user.username
        this.email = this.user.email
        alert('Utilisateur créé !')
      } catch (err) {
        console.error(err)
        alert('Erreur lors de la création')
      }
    },

    async getUser() {
      const id = this.$route.params.userID || this.user?.id
      if (!id) return
      try {
        const res = await api.get(`/users/${id}`)
        this.user = res.data.data
        this.username = this.user.username
        this.email = this.user.email
      } catch (err) {
        console.error(err)
      }
    },

    async updateUser() {
      if (!this.user?.id) return alert('Aucun user à mettre à jour')
      try {
        const res = await api.put(`/users/${this.user.id}`, {
          user: {
            username: this.username,
            email: this.email
          }
        })
        this.user = res.data.data
        alert('Utilisateur mis à jour !')
      } catch (err) {
        console.error(err)
      }
    },

    async deleteUser() {
      if (!this.user?.id) return alert('Aucun user à supprimer')
      if (!confirm('Confirmer la suppression ?')) return
      try {
        await api.delete(`/users/${this.user.id}`)
        this.user = null
        this.username = ''
        this.email = ''
        alert('Utilisateur supprimé !')
      } catch (err) {
        console.error(err)
      }
    }
  }
}
</script>
