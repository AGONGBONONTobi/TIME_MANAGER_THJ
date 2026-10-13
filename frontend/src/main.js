import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import 'bootstrap/dist/css/bootstrap.min.css'
import './assets/noir-theme.css'
import { initialiseAndroidBackButton } from './services/nativeFeatures'

const app = createApp(App)

app.use(router)

app.mount('#app')

const splashMinimumDuration = 3000
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
}

if (globalThis.cordova) {
  const splash = document.querySelector('#startup-splash')
  if (splash) {
    splash.style.display = 'grid'
    splashStartedAt = performance.now()
  }

  document.addEventListener('deviceready', () => {
    hideStartupSplash()
  }, { once: true })
  window.setTimeout(hideStartupSplash, 10000)
}

const stopBackButton = initialiseAndroidBackButton(router)
app.config.globalProperties.$stopBackButton = stopBackButton
