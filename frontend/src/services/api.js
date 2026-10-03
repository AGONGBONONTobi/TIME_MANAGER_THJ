import axios from 'axios'
import { clearAuthUser, getCsrfToken } from '../utils/auth'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json'
  }
})

api.interceptors.request.use((config) => {
  const csrfToken = getCsrfToken()

  if (csrfToken && config.headers) {
    config.headers['x-xsrf-token'] = csrfToken
  }

  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error?.response?.status === 401) {
      clearAuthUser()
      if (window.location.pathname !== '/sign_in') {
        window.location.href = '/sign_in'
      }
    }

    return Promise.reject(error)
  }
)

api.getUser = (userID) => api.get(`/users/${userID}`)
api.createUser = (user) => api.post('/users', { user })
api.updateUser = (userID, user) => api.put(`/users/${userID}`, { user })
api.deleteUser = (userID) => api.delete(`/users/${userID}`)
api.getClocks = (userID) => api.get(`/clocks/${userID}`)
api.clockInOut = (userID) => api.post(`/clocks/${userID}`)
api.getWorkingTimes = (userID, start, end) => api.get(`/workingtime/${userID}`, {
  params: { start, end }
})
api.getWorkingTime = (userID, workingTimeID) => api.get(`/workingtime/${userID}/${workingTimeID}`)
api.createWorkingTime = (userID, workingTime) => api.post(`/workingtime/${userID}`, { workingtime: workingTime })
api.updateWorkingTime = (workingTimeID, workingTime) => api.put(`/workingtime/${workingTimeID}`, { workingtime: workingTime })
api.deleteWorkingTime = (workingTimeID) => api.delete(`/workingtime/${workingTimeID}`)

export default api
