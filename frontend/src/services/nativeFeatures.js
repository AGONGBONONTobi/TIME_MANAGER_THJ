export function vibrateSuccess() {
  if (typeof navigator !== 'undefined' && navigator.vibrate) navigator.vibrate([40, 30, 40])
}

export function notifySync(message = 'Vos pointages sont synchronisés.') {
  const plugin = globalThis.cordova?.plugins?.notification?.local
  if (plugin) {
    plugin.schedule({ title: 'Time Manager', text: message, foreground: true })
  }
}

export function initialiseAndroidBackButton(router) {
  const handler = () => {
    if (globalThis.cordova?.platformId !== 'android') return
    if (router.currentRoute.value.meta?.guestOnly || router.currentRoute.value.path === '/dashboard') {
      navigator.app.exitApp()
      return
    }
    router.back()
  }
  document.addEventListener('backbutton', handler, false)
  return () => document.removeEventListener('backbutton', handler, false)
}
