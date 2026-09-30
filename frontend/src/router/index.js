import { createRouter, createWebHistory } from 'vue-router'
import User from '../components/User.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'
import AdminDashboard from '../components/AdminDashboard.vue'
import ManageDashboard from '@/components/ManageDashboard.vue'

const routes = [
  {
    path: '/workingTimes/:userID',
    name: 'workingTimes',
    component: WorkingTimes,
    props: true
  },
  {
    path: '/clock/:userID',
    name: 'clock',
    component: ClockManager,
    props: true
  },
  {
    path: '/chartManager/:userID',
    name: 'chartManager',
    component: ChartManager,
    props: true
  },
  {
    path: '/user',
    name: 'user',
    component: User
  },
  {
    path: '/manager-dashboard',
    name: 'managerDashboard',
    component: ManageDashboard
  },
  {
    path: '/admin-dashboard',
    name: 'adminDashboard',
    component: AdminDashboard,
    meta: { demoOnly: true }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: { name: 'user' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
