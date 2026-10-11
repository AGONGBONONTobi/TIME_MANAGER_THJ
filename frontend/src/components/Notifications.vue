<script>
import api from '../services/api'

export default {
  name: 'NotificationsPage',
  data: () => ({ notifications: [], loading: true, error: '' }),
  computed: {
    unread() { return this.notifications.filter((item) => !item.read_at).length }
  },
  mounted() { this.load() },
  methods: {
    async load() {
      this.loading = true
      try { this.notifications = (await api.getNotifications()).data?.data || [] } catch { this.error = 'Impossible de charger les notifications.' } finally { this.loading = false }
    },
    async markRead(notification) {
      if (notification.read_at) return
      try { const response = await api.markNotificationRead(notification.id); notification.read_at = response.data?.data?.read_at || new Date().toISOString() } catch { this.error = 'La notification n’a pas pu être marquée comme lue.' }
    }
  }
}
</script>

<template>
  <section class="notifications-page">
    <div class="page-heading-block"><p class="eyebrow">CENTRE D’ACTIVITÉ</p><h1>Notifications</h1><p>{{ unread }} non lue{{ unread > 1 ? 's' : '' }}</p></div>
    <p v-if="error" class="error-message">{{ error }}</p>
    <div v-if="loading">Chargement…</div>
    <div v-else-if="!notifications.length" class="empty-state">Aucune notification.</div>
    <article v-for="notification in notifications" v-else :key="notification.id" class="notification-card" :class="{ unread: !notification.read_at }">
      <div><strong>{{ notification.message }}</strong><small>{{ new Date(notification.inserted_at).toLocaleString('fr-FR') }}</small></div>
      <button v-if="!notification.read_at" type="button" @click="markRead(notification)">Marquer comme lu</button>
    </article>
  </section>
</template>

<style scoped>
.notifications-page { max-width: 820px; margin: auto; }.page-heading-block { margin-bottom: 24px; }.page-heading-block h1 { margin: 0; }.page-heading-block p:last-child { color: #716b64; }.notification-card { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin: 10px 0; padding: 16px; background: #fff; border: 1px solid #e5e7eb; border-radius: 10px; }.notification-card.unread { border-left: 4px solid #786be7; }.notification-card strong, .notification-card small { display: block; }.notification-card small { margin-top: 6px; color: #777; }.notification-card button { padding: 8px 12px; color: #fff; background: #786be7; border: 0; border-radius: 6px; cursor: pointer; }
</style>
