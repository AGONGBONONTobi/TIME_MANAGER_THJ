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
<<<<<<< HEAD
    path: '/workingTime/:userID',
    name: 'workingTimeCreate',
    component: WorkingTime,
    props: true
  },
  {
    path: '/workingTime/:userID/:workingtimeid',
    name: 'workingTimeEdit',
    component: WorkingTime,
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
    component: User,
    props: true
=======
    path: '/user',
    name: 'user',
    component: User
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: { name: 'user' }
>>>>>>> 6b9108d3791c70f2470c5e7df48edaf33090ac2f
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
