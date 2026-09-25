<script>
import api from '../services/api'

export default {
  name: 'WorkingTime',
  data() {
    return {
      workingTime: null
    }
  },
  mounted() {
    this.fetchWorkingTime()
  },
  methods: {
    async createWorkingTime() {
      const id = this.$route.params.userID
      if (!id) return alert ("Aucun user!")
      try {
        const res = await api.post(`/workingtime/${id}`, {
          start_at: this.start_at,
          end_at: this.end_at
        })
        this.workingTime = res.data.data
        // this.id = this.workingTime.id;
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
      if (!id) return
      try {
        const res = await api.put(`workingtime/${id}`, {
          // const l = res.data.data;
          start_at : this.start_at,
          end_at : this.end_at
        })
        this.workingTime = res.data.data
        this.start_at = this.workingTime.start_at
        this.end_at = this.workingTime.end_at
        alert(`workingtime ${id} mis à jour`);
      } catch (err) {
        console.error(err)
      }
    },
    async deleteWorkingTime() {
      const id = this.$route.workingTime.id || this.user?.id
      if (!id) return alert('Aucun workingtime à supprimer')
            if (!confirm('Confirmer la suppression ?')) return
      try {
        await api.delete(`workingtime/${id}`);
        this.workingTime = null
        this.start_at = ''
        this.end_at = ''
        alert("workingtime supprimé")
      } catch (err) {
        console.error(err)
      }
    },
    fetchWorkingTime() {
      // Simulate fetching working time data from an API or service
      // setTimeout(() => {
      //   this.workingTime = '9:00 AM - 5:00 PM'
      // }, 1000)
    }
  }
}

</script>

<template></template>


<style scoped>

</style>
