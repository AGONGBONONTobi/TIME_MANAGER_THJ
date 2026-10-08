import axios from 'axios'
import { clearAuthUser, getAuthToken, getCsrfToken } from '../utils/auth'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json'
  }
})

api.interceptors.request.use(async (config) => {
  const csrfToken = getCsrfToken()

  if (csrfToken && config.headers) {
    config.headers['x-xsrf-token'] = csrfToken
  }

  const authToken = await getAuthToken()
  if (authToken && config.headers) {
    config.headers.Authorization = `Bearer ${authToken}`
  }

  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error?.response?.status === 401) {
      clearAuthUser()
      if (window.location.hash !== '#/sign_in') {
        window.location.hash = '#/sign_in'
      }
    }

    return Promise.reject(error)
  }
)

api.getUser = (userID) => api.get(`/users/${userID}`)
api.getUsers = (params = {}) => api.get('/users', { params })
api.getCurrentUser = () => api.get('/auth/me')
api.getUserWorkPolicy = (userID) => api.get(`/users/${userID}/work-policy`)
api.createUser = (user) => api.post('/users', { user })
api.updateUser = (userID, user) => api.put(`/users/${userID}`, { user })
api.deleteUser = (userID) => api.delete(`/users/${userID}`)
api.getManagerTeam = () => api.get('/manager/team')
api.sendClockReminder = (userID) => api.post(`/manager/users/${userID}/reminders`)
api.getNotifications = () => api.get('/notifications')
api.markNotificationRead = (id) => api.patch(`/notifications/${id}/read`)
api.getTeams = () => api.get('/teams')
api.createTeam = (team) => api.post('/teams', { team })
api.addTeamMember = (teamID, userID) => api.post(`/teams/${teamID}/members/${userID}`)
api.removeTeamMember = (teamID, userID) => api.delete(`/teams/${teamID}/members/${userID}`)
api.getTeamTasks = (teamID) => api.get(`/teams/${teamID}/tasks`)
api.createTeamTask = (teamID, task) => api.post(`/teams/${teamID}/tasks`, { task })
api.updateTeamTaskStatus = (teamID, taskID, status) => api.patch(`/teams/${teamID}/tasks/${taskID}/status`, { status })
api.getLeaveRequests = () => api.get('/leave-requests')
api.createLeaveRequest = (leaveRequest) => api.post('/leave-requests', { leave_request: leaveRequest })
api.approveLeaveRequest = (id) => api.post(`/leave-requests/${id}/approve`)
api.rejectLeaveRequest = (id) => api.post(`/leave-requests/${id}/reject`)
api.getPayrollRules = () => api.get('/payroll-rules')
api.getWorkPolicies = () => api.get('/work-policies')
api.getClocks = (userID) => api.get(`/users/${userID}/clocks`)
api.clockInOut = (userID, payload = {}) => api.post(`/users/${userID}/clocks`, payload)
api.getWorkingTimes = (userID, start, end) => api.get(`/users/${userID}/working-times`, {
  params: { start, end }
})
api.getWorkingTime = (userID, workingTimeID) => api.get(`/users/${userID}/working-times/${workingTimeID}`)
api.createWorkingTime = (userID, workingTime) => api.post(`/users/${userID}/working-times`, { workingtime: workingTime })
api.updateWorkingTime = (workingTimeID, workingTime) => api.put(`/workingtime/${workingTimeID}`, { workingtime: workingTime })
api.deleteWorkingTime = (workingTimeID) => api.delete(`/workingtime/${workingTimeID}`)

export default api
