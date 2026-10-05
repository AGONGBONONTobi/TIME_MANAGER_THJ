import { createRouter, createWebHistory } from 'vue-router'
import User from '../components/User.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
<<<<<<< HEAD
import HR from '../components/HR.vue'
import ManageDashboard from '@/components/ManageDashboard.vue'
=======
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'
import AdminDashboard from '../components/AdminDashboard.vue'
import ManageDashboard from '@/components/ManageDashboard.vue'
import Authentication from '../components/Authentication.vue'
import Register from '../components/Register.vue'
import Dashboard from '../components/Dashboard.vue'
import Unauthorized from '../components/Unauthorized.vue'
import { readAuthUser } from '../utils/auth'
>>>>>>> f7e66514d42a420eacf40b4387aeb9989e4b2d78

const routes = [
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/sign_in',
    name: 'signIn',
    component: Authentication,
    meta: { guestOnly: true }
  },
  {
    path: '/sign_up',
    name: 'signUp',
    component: Register,
    meta: { guestOnly: true }
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: Dashboard,
    meta: { requiresAuth: true }
  },
  {
    path: '/employee',
    name: 'employee',
    component: User,
    meta: { requiresAuth: true, roles: ['employee', 'manager', 'admin'] }
  },
  {
    path: '/manager',
    name: 'manager',
    component: ManageDashboard,
    meta: { requiresAuth: true, roles: ['manager', 'admin'] }
  },
  {
    path: '/admin',
    name: 'admin',
    component: AdminDashboard,
    meta: { requiresAuth: true, roles: ['admin'] }
  },
  {
    path: '/unauthorized',
    name: 'unauthorized',
    component: Unauthorized
  },
  {
    path: '/workingTimes/:userID',
    name: 'workingTimes',
    component: WorkingTimes,
<<<<<<< HEAD
    props: true
=======
    props: true,
    meta: { requiresAuth: true }
  },
  {
    path: '/clock/:userID',
    name: 'clock',
    component: ClockManager,
    props: true,
    meta: { requiresAuth: true }
  },
  {
    path: '/chartManager/:userID',
    name: 'chartManager',
    component: ChartManager,
    props: true,
    meta: { requiresAuth: true }
>>>>>>> f7e66514d42a420eacf40b4387aeb9989e4b2d78
  },
  {
    path: '/user',
    name: 'user',
<<<<<<< HEAD
    component: User
  },
  {
    path: '/admin-dashboard',
    name: 'adminDashboard',
    component: HR
  },
  {
    path: '/hr',
    redirect: { name: 'adminDashboard' }
  },
  {
    path: '/manager-dashboard',
    name: 'managerDashboard',
    component: ManageDashboard
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: { name: 'user' }
=======
    component: User,
    meta: { requiresAuth: true, roles: ['employee', 'manager', 'admin'] }
  },
  {
    path: '/manager-dashboard',
    name: 'managerDashboard',
    redirect: '/manager'
  },
  {
    path: '/admin-dashboard',
    name: 'adminDashboard',
    redirect: '/admin'
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard'
>>>>>>> f7e66514d42a420eacf40b4387aeb9989e4b2d78
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to) => {
  const currentUser = readAuthUser()
  const isAuthenticated = Boolean(currentUser && currentUser.id && currentUser.role)

  if (to.meta?.guestOnly && isAuthenticated) {
    return '/dashboard'
  }

  if (to.meta?.requiresAuth && !isAuthenticated) {
    return { path: '/sign_in', query: { redirect: to.fullPath } }
  }

  if (to.meta?.roles && currentUser && !to.meta.roles.includes(String(currentUser.role).toLowerCase())) {
    return '/unauthorized'
  }

  return true
})

export default router
