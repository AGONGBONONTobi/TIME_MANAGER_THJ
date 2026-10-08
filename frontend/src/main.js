import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import 'bootstrap/dist/css/bootstrap.min.css'
import './assets/noir-theme.css'
import { initialiseAndroidBackButton } from './services/nativeFeatures'

const app = createApp(App)

app.use(router)

app.mount('#app')
const stopBackButton = initialiseAndroidBackButton(router)
app.config.globalProperties.$stopBackButton = stopBackButton
