let online = true
const listeners = new Set()

function notify() {
  listeners.forEach((listener) => listener(online))
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent('time-manager-network', { detail: { online } }))
  }
}

export function isOnline() {
  return online
}

export function subscribeNetwork(listener) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

export function initialiseNetworkMonitoring() {
  if (typeof window === 'undefined') return () => {}
  const update = (event) => {
    online = event.type === 'online'
    notify()
  }
  window.addEventListener('online', update)
  window.addEventListener('offline', update)
  document.addEventListener('deviceready', () => {
    if (window.navigator?.connection) {
      online = window.navigator.connection.type !== 'none'
      notify()
    }
  }, { once: true })
  return () => {
    window.removeEventListener('online', update)
    window.removeEventListener('offline', update)
  }
}
