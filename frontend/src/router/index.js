import { createRouter, createWebHistory } from 'vue-router'
import User from '../components/User.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import WorkingTime from '../components/WorkingTime.vue'
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'
const routes = [
  {
    path: '/workingTimes/:userID',
    name: 'workingTimes',
    component: WorkingTimes,
    props: true
  },
  {
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
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
