export const AUTH_STORAGE_KEY = 'time_manager_user'
export const AUTH_TOKEN_STORAGE_KEY = 'time_manager_token'

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
      role: String(parsed.role)
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
    role: String(user.role)
  }

  window.localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(payload))
  return payload
}

function secureStorage() {
  const SecureStorage = globalThis.cordova?.plugins?.SecureStorage
  if (!SecureStorage) return Promise.resolve(null)
  return new Promise((resolve) => {
    try {
      resolve(new SecureStorage(() => {}, () => {}, 'time_manager'))
    } catch {
      resolve(null)
    }
  })
}

export async function writeAuthToken(token) {
  if (!token) return ''
  const storage = await secureStorage()
  if (storage) {
    await new Promise((resolve, reject) => storage.set(resolve, reject, AUTH_TOKEN_STORAGE_KEY, token))
  } else if (typeof window !== 'undefined') {
    window.localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, token)
  }
  return token
}

export async function getAuthToken() {
  const storage = await secureStorage()
  if (storage) {
    return new Promise((resolve) => storage.get(resolve, () => resolve(''), AUTH_TOKEN_STORAGE_KEY))
  }
  return typeof window === 'undefined' ? '' : window.localStorage.getItem(AUTH_TOKEN_STORAGE_KEY) || ''
}

export async function clearAuthUser() {
  if (typeof window !== 'undefined') {
    window.localStorage.removeItem(AUTH_STORAGE_KEY)
    window.localStorage.removeItem(AUTH_TOKEN_STORAGE_KEY)
  }
  const storage = await secureStorage()
  if (storage) {
    await new Promise((resolve) => storage.remove(resolve, resolve, AUTH_TOKEN_STORAGE_KEY))
  }
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
