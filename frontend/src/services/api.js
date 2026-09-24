import axios from 'axios'

const API_URL = 'http://localhost:4000/api'

export default {

  getUser(userID) {
    return axios.get(`${API_URL}/users/${userID}`)
  },

  createUser(user) {
    return axios.post(`${API_URL}/users`, { user })
  },

  updateUser(userID, user) {
    return axios.put(`${API_URL}/users/${userID}`, { user })
  },

  deleteUser(userID) {
    return axios.delete(`${API_URL}/users/${userID}`)
  },

  getClocks(userID) {
    return axios.get(`${API_URL}/clocks/${userID}`)
  },

  clockInOut(userID) {
    return axios.post(`${API_URL}/clocks/${userID}`)
  },

  getWorkingTimes(userID, start, end) {
    return axios.get(`${API_URL}/workingtime/${userID}`, {
      params: { start, end }
    })
  },

  getWorkingTime(userID, id) {
    return axios.get(`${API_URL}/workingtime/${userID}/${id}`)
  },

  createWorkingTime(userID, workingTime) {
    return axios.post(`${API_URL}/workingtime/${userID}`, {
      workingtime: workingTime
    })
  },

  updateWorkingTime(id, workingTime) {
    return axios.put(`${API_URL}/workingtime/${id}`, {
      workingtime: workingTime
    })
  },

  deleteWorkingTime(id) {
    return axios.delete(`${API_URL}/workingtime/${id}`)
  }
}
