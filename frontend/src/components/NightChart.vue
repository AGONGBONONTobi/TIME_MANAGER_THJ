<script>
import api from '../services/api'
export default {
  name: 'NightChart',
  data: () => ({ employees: [], error: '' }),
  computed: { maxNights() { return Math.max(...this.employees.map((item) => Number(item.nights || 0)), 1) } },
  mounted() { this.load() },
  methods: { async load() { try { this.employees = (await api.getManagerTeam()).data?.data || [] } catch { this.error = 'Impossible de charger les nuits.' } } }
}
</script>
<template><section class="night-chart"><h2>Évolution des nuits</h2><p v-if="error">{{ error }}</p><div v-for="employee in employees" :key="employee.id" class="night-row"><span>{{ employee.name }}</span><div><i :style="{ width: `${Math.min(100, Number(employee.nights || 0) / maxNights * 100)}%` }"></i></div><strong>{{ employee.nights || 0 }}</strong></div></section></template>
<style scoped>
.night-chart { padding: 20px; background: #fff; border-radius: 10px; min-width: 0; box-sizing: border-box; }
.night-row { display: grid; grid-template-columns: minmax(80px, 150px) 1fr 30px; align-items: center; gap: 10px; margin: 12px 0; min-width: 0; }
.night-row span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 12px; }
.night-row div { height: 9px; background: #ece9ff; border-radius: 10px; min-width: 0; overflow: hidden; }
.night-row i { display: block; height: 100%; background: #786be7; border-radius: inherit; }
@media (max-width: 450px) {
  .night-chart { padding: 15px 12px; }
  .night-row { grid-template-columns: 75px 1fr 25px; gap: 8px; font-size: 11px; }
}
</style>
