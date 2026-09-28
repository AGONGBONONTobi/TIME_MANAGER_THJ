import { createRouter, createWebHistory } from 'vue-router'
import User from '../components/User.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
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
    path: '/:pathMatch(.*)*',
    redirect: { name: 'user' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
