import { createRouter, createWebHistory } from 'vue-router'
import User from '../components/User.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import HR from '../components/HR.vue'
import ManageDashboard from '@/components/ManageDashboard.vue'

const routes = [
  {
    path: '/workingTimes/:userID',
    name: 'workingTimes',
    component: WorkingTimes,
    props: true
  },
  {
    path: '/user',
    name: 'user',
    component: User
  },
  {
    path: '/hr',
    name: 'hr',
    component: HR
  },
  {
    path: '/manager-dashboard',
    name: 'managerDashboard',
    component: ManageDashboard
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
