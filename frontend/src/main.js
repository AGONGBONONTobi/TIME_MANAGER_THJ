import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import 'bootstrap/dist/css/bootstrap.min.css'
import './assets/noir-theme.css'
import { initialiseAndroidBackButton } from './services/nativeFeatures'

const app = createApp(App)

app.use(router)

app.mount('#app')

const hideStartupSplash = () => {
  const splash = document.querySelector('#startup-splash')
  if (!splash) return

  splash.classList.add('is-hidden')
  splash.addEventListener('transitionend', () => splash.remove(), { once: true })
}

if (globalThis.cordova) {
  document.addEventListener('deviceready', () => {
    window.setTimeout(hideStartupSplash, 250)
  }, { once: true })
  window.setTimeout(hideStartupSplash, 10000)
} else {
  hideStartupSplash()
}

const stopBackButton = initialiseAndroidBackButton(router)
app.config.globalProperties.$stopBackButton = stopBackButton
