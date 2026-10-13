import api from '../../../src/services/api'
import {
  AUTH_STORAGE_KEY,
  AUTH_TOKEN_STORAGE_KEY,
  getAuthToken,
  writeAuthToken,
  writeAuthUser
} from '../../../src/utils/auth'

describe('API authentication handling', () => {
  let secureValues
  let originalAdapter

  beforeEach(() => {
    secureValues = {}
    globalThis.cordova = {
      plugins: {
        SecureStorage: class {
          constructor(success) {
            queueMicrotask(success)
          }

          keys(success) {
            queueMicrotask(() => success(Object.keys(secureValues)))
          }

          get(success, error, key) {
            if (Object.hasOwn(secureValues, key)) {
              queueMicrotask(() => success(secureValues[key]))
            } else {
              queueMicrotask(() => error(new Error(`Missing key: ${key}`)))
            }
          }

          set(success, _error, key, value) {
            secureValues[key] = value
            queueMicrotask(success)
          }

          remove(success, _error, key) {
            delete secureValues[key]
            queueMicrotask(() => success(key))
          }
        }
      }
    }
    localStorage.clear()
    originalAdapter = api.defaults.adapter
    window.location.hash = '#/employee'
  })

  afterEach(() => {
    api.defaults.adapter = originalAdapter
    delete globalThis.cordova
    localStorage.clear()
  })

  it('does not let a late 401 from an old token clear a newer login', async () => {
    await writeAuthToken('old-token')
    writeAuthUser({ id: 7, username: 'Employee', role: 'employee' })

    let requestConfig
    let rejectRequest
    let markAdapterStarted
    const adapterStarted = new Promise((resolve) => {
      markAdapterStarted = resolve
    })

    api.defaults.adapter = (config) => {
      requestConfig = config
      markAdapterStarted()
      return new Promise((_resolve, reject) => {
        rejectRequest = reject
      })
    }

    const request = api.getCurrentUser()
    await adapterStarted
    await writeAuthToken('new-token')
    rejectRequest({
      config: requestConfig,
      response: { status: 401, config: requestConfig }
    })

    await expect(request).rejects.toMatchObject({ response: { status: 401 } })
    expect(await getAuthToken()).toBe('new-token')
    expect(JSON.parse(localStorage.getItem(AUTH_STORAGE_KEY))).toMatchObject({ id: 7 })
    expect(window.location.hash).toBe('#/employee')
  })

  it('does not let an unauthenticated startup request clear a new login', async () => {
    writeAuthUser({ id: 7, username: 'Employee', role: 'employee' })

    let requestConfig
    let rejectRequest
    let markAdapterStarted
    const adapterStarted = new Promise((resolve) => {
      markAdapterStarted = resolve
    })

    api.defaults.adapter = (config) => {
      requestConfig = config
      markAdapterStarted()
      return new Promise((_resolve, reject) => {
        rejectRequest = reject
      })
    }

    const request = api.getCurrentUser()
    await adapterStarted
    await writeAuthToken('new-token')
    rejectRequest({
      config: requestConfig,
      response: { status: 401, config: requestConfig }
    })

    await expect(request).rejects.toMatchObject({ response: { status: 401 } })
    expect(await getAuthToken()).toBe('new-token')
    expect(JSON.parse(localStorage.getItem(AUTH_STORAGE_KEY))).toMatchObject({ id: 7 })
    expect(window.location.hash).toBe('#/employee')
  })

  it('clears the current mobile session when its own token is rejected', async () => {
    await writeAuthToken('rejected-token')
    writeAuthUser({ id: 7, username: 'Employee', role: 'employee' })

    api.defaults.adapter = async (config) => {
      throw { config, response: { status: 401, config } }
    }

    await expect(api.getCurrentUser()).rejects.toMatchObject({ response: { status: 401 } })
    expect(await getAuthToken()).toBe('')
    expect(secureValues[AUTH_TOKEN_STORAGE_KEY]).toBeUndefined()
    expect(localStorage.getItem(AUTH_STORAGE_KEY)).toBeNull()
    expect(window.location.hash).toBe('#/sign_in')
  })
})
