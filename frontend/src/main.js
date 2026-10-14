import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import 'bootstrap/dist/css/bootstrap.min.css'
import './assets/noir-theme.css'
import { initialiseAndroidBackButton } from './services/nativeFeatures'

const app = createApp(App)

app.use(router)

app.mount('#app')

const splashMinimumDuration = 2800
let splashStartedAt

const hideStartupSplash = () => {
  const splash = document.querySelector('#startup-splash')
  if (!splash) return

  splashStartedAt ??= performance.now()
  const remainingDuration = Math.max(0, splashMinimumDuration - (performance.now() - splashStartedAt))
  if (remainingDuration > 0) {
    window.setTimeout(hideStartupSplash, remainingDuration)
    return
  }

  splash.classList.add('is-hidden')
  splash.addEventListener('transitionend', () => splash.remove(), { once: true })
  window.setTimeout(() => splash?.remove(), 600)
}

const isMobileApp = Boolean(
  globalThis.cordova ||
  import.meta.env.MODE === 'mobile' ||
  window.location.search.includes('mobile') ||
  (window.innerWidth <= 768 && ('ontouchstart' in window || navigator.maxTouchPoints > 0 || /Android|iPhone|iPad|iPod/i.test(navigator.userAgent)))
)

const splash = document.querySelector('#startup-splash')

if (isMobileApp && splash) {
  document.body.classList.add('is-mobile-app')
  splash.style.display = 'flex'
  splashStartedAt = performance.now()

  if (globalThis.cordova) {
    document.addEventListener('deviceready', () => {
      hideStartupSplash()
    }, { once: true })
    window.setTimeout(hideStartupSplash, 6000)
  } else {
    window.setTimeout(hideStartupSplash, splashMinimumDuration)
  }
} else if (splash) {
  splash.remove()
}

const stopBackButton = initialiseAndroidBackButton(router)
app.config.globalProperties.$stopBackButton = stopBackButton
