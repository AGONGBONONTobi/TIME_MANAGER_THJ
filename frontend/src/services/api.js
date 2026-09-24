import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  headers: {
    'Content-Type': 'application/json'
  }
})

api.getUser = (userID) => api.get(`/users/${userID}`)
api.createUser = (user) => api.post('/users', { user })
api.updateUser = (userID, user) => api.put(`/users/${userID}`, { user })
api.deleteUser = (userID) => api.delete(`/users/${userID}`)
api.getClocks = (userID) => api.get(`/clocks/${userID}`)
api.clockInOut = (userID) => api.post(`/clocks/${userID}`)
api.getWorkingTimes = (userID, start, end) => api.get(`/workingtime/${userID}`, {
  params: { start, end }
})
api.getWorkingTime = (userID, id) => api.get(`/workingtime/${userID}/${id}`)
api.createWorkingTime = (userID, workingTime) => api.post(`/workingtime/${userID}`, {
  workingtime: workingTime
})
api.updateWorkingTime = (id, workingTime) => api.put(`/workingtime/${id}`, {
  workingtime: workingTime
})
api.deleteWorkingTime = (id) => api.delete(`/workingtime/${id}`)

export default api
