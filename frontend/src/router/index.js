import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/workingTimes/:userID',
    name: 'workingTimes',
    component: "",
    props: true
  },
  {
    path: '/workingTime/:userid',
    name: 'workingTime',
    component: "",
    props: true
  },
  {
    path: '/workingTime/:userid/:workingtimeid',
    name: 'workingTime',
    component: "",
    props: true
  },
  {
    path: '/clock/:userid',
    name: 'clock',
    component: "",
    props: true
  },
  {
    path: '/chartManager/:userid',
    name: 'chartManager',
    component: "",
    props: true
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

export default router
