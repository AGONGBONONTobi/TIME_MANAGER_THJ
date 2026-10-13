export const AUTH_STORAGE_KEY = 'time_manager_user'
export const AUTH_TOKEN_STORAGE_KEY = 'time_manager_token'
export const AUTH_CSRF_STORAGE_KEY = 'time_manager_csrf_token'

let authSessionRevision = 0

export function getAuthSessionRevision() {
  return authSessionRevision
}

export function readAuthUser() {
  if (typeof window === 'undefined') {
    return null
  }

  try {
    const rawValue = window.localStorage.getItem(AUTH_STORAGE_KEY)
    if (!rawValue) {
      return null
    }

    const parsed = JSON.parse(rawValue)
    if (!parsed || !parsed.id || !parsed.role) {
      window.localStorage.removeItem(AUTH_STORAGE_KEY)
      return null
    }

    return {
      id: Number(parsed.id),
      username: parsed.username || '',
      role: String(parsed.role),
      onboarded_at: parsed.onboarded_at || null,
      must_change_password: Boolean(parsed.must_change_password)
    }
  } catch {
    window.localStorage.removeItem(AUTH_STORAGE_KEY)
    return null
  }
}

export function writeAuthUser(user) {
  if (!user || !user.id || !user.role) {
    return null
  }

  const payload = {
    id: Number(user.id),
    username: user.username || '',
    role: String(user.role),
    onboarded_at: user.onboarded_at || null,
    must_change_password: Boolean(user.must_change_password)
  }

  window.localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(payload))
  return payload
}

export function isCordovaApp() {
  return import.meta.env.MODE === 'mobile' || typeof globalThis.cordova !== 'undefined'
}

function secureStorage() {
  if (!isCordovaApp()) {
    return Promise.resolve(null)
  }

  const SecureStorage = globalThis.cordova?.plugins?.SecureStorage
  if (!SecureStorage) {
    return Promise.reject(new Error('Secure storage unavailable; cannot authenticate securely.'))
  }

  return new Promise((resolve, reject) => {
    let storage
    try {
      storage = new SecureStorage(() => resolve(storage), reject, 'time_manager')
    } catch (error) {
      reject(error)
    }
  })
}

async function getSecureValue(storage, key) {
  const keys = await new Promise((resolve, reject) => storage.keys(resolve, reject))
  if (!keys.includes(key)) {
    return ''
  }
  return new Promise((resolve, reject) => storage.get(resolve, reject, key))
}

async function writeSecureValue(key, value) {
  if (!isCordovaApp()) {
    return ''
  }
  if (typeof value !== 'string' || !value) {
    throw new Error('The server did not provide the secure authentication credentials required by the mobile app.')
  }
  const storage = await secureStorage()
  await new Promise((resolve, reject) => storage.set(resolve, reject, key, value))
  return value
}

export function writeAuthToken(token) {
  authSessionRevision += 1
  return writeSecureValue(AUTH_TOKEN_STORAGE_KEY, token)
}

export function writeAuthCsrfToken(token) {
  return writeSecureValue(AUTH_CSRF_STORAGE_KEY, token)
}

export async function getAuthToken() {
  if (!isCordovaApp()) {
    return ''
  }
  const storage = await secureStorage()
  return getSecureValue(storage, AUTH_TOKEN_STORAGE_KEY)
}

export async function getAuthCsrfToken() {
  if (!isCordovaApp()) {
    return ''
  }
  const storage = await secureStorage()
  return getSecureValue(storage, AUTH_CSRF_STORAGE_KEY)
}

export async function clearAuthUser() {
  authSessionRevision += 1
  if (typeof window !== 'undefined') {
    window.localStorage.removeItem(AUTH_STORAGE_KEY)
    window.localStorage.removeItem(AUTH_TOKEN_STORAGE_KEY)
  }
  if (!isCordovaApp()) {
    return
  }
  const storage = await secureStorage()
  const keys = await new Promise((resolve, reject) => storage.keys(resolve, reject))
  for (const key of [AUTH_TOKEN_STORAGE_KEY, AUTH_CSRF_STORAGE_KEY]) {
    if (keys.includes(key)) {
      await new Promise((resolve, reject) => storage.remove(resolve, reject, key))
    }
  }
}

export async function clearAuthUserIfCurrent(token, revision) {
  if (!token || revision !== authSessionRevision) {
    return false
  }

  const currentToken = await getAuthToken()
  if (revision !== authSessionRevision || currentToken !== token) {
    return false
  }

  await clearAuthUser()
  return true
}

export function getCsrfToken() {
  if (typeof document === 'undefined') {
    return ''
  }

  const cookies = document.cookie.split(';')
  const match = cookies.find((cookie) => cookie.trim().startsWith('c-xsrf-token='))

  if (!match) {
    return ''
  }

  return decodeURIComponent(match.split('=').slice(1).join('=')).trim()
}
