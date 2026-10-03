export const AUTH_STORAGE_KEY = 'time_manager_user'

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

export function clearAuthUser() {
  if (typeof window !== 'undefined') {
    window.localStorage.removeItem(AUTH_STORAGE_KEY)
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
