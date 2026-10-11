<script>
export default {
  name: 'OnboardingWizard',
  props: {
    userName: { type: String, default: 'Utilisateur' },
    userRole: { type: String, default: 'employee' }
  },
  emits: ['complete', 'skip'],
  data() {
    return {
      currentStep: 0,
      steps: [
        {
          icon: '👋',
          title: 'Bienvenue sur Time Manager',
          text: `Bonjour ${this.userName}, nous allons te faire découvrir l'application en 1 minute.`,
          highlight: null
        },
        {
          icon: '⏰',
          title: 'Pointer ton temps',
          text: 'Utilise le bouton "Clock In" pour démarrer ta journée et "Clock Out" pour la terminer. Un chronomètre s\'affichera automatiquement.',
          highlight: 'clock-action'
        },
        {
          icon: '📊',
          title: 'Suivre ton quota hebdomadaire',
          text: 'Ton objectif est de 70% du temps contractuel. La jauge change de couleur selon ta progression : 🔴 < 50%, 🟡 < 70%, 🟢 ≥ 70%.',
          highlight: 'quota-section'
        },
        {
          icon: '📈',
          title: 'Visualiser tes heures',
          text: 'Les graphiques te montrent tes heures travaillées, tes heures de nuit et ton rythme hebdomadaire.',
          highlight: 'activity-chart'
        },
        {
          icon: '✨',
          title: 'Tout est prêt !',
          text: 'Tu peux maintenant utiliser Time Manager. Si tu as des questions, contacte ton manager ou le service RH.',
          highlight: null
        }
      ]
    }
  },
  computed: {
    step() { return this.steps[this.currentStep] },
    isLastStep() { return this.currentStep === this.steps.length - 1 },
    isFirstStep() { return this.currentStep === 0 }
  },
  methods: {
    next() {
      if (this.isLastStep) this.finish()
      else this.currentStep++
    },
    prev() {
      if (!this.isFirstStep) this.currentStep--
    },
    finish() {
      this.$emit('complete')
    },
    skip() {
      this.$emit('skip')
    }
  }
}
</script>

<template>
  <div class="onboarding-overlay" role="dialog" aria-modal="true">
    <div class="onboarding-modal">
      <!-- Bouton skip -->
      <button class="skip-btn" type="button" @click="skip" aria-label="Passer">
        Passer ✕
      </button>

      <!-- Contenu -->
      <div class="onboarding-content">
        <div class="onboarding-icon">{{ step.icon }}</div>
        <h2>{{ step.title }}</h2>
        <p>{{ step.text }}</p>
      </div>

      <!-- Progression -->
      <div class="progress-dots">
        <span
          v-for="(s, i) in steps"
          :key="i"
          :class="{ active: i === currentStep, done: i < currentStep }"
        />
      </div>

      <!-- Actions -->
      <div class="onboarding-actions">
        <button
          v-if="!isFirstStep"
          class="btn-secondary"
          type="button"
          @click="prev"
        >
          ← Précédent
        </button>
        <span v-else />
        <button class="btn-primary" type="button" @click="next">
          {{ isLastStep ? 'C\'est parti ! ✨' : 'Suivant →' }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.onboarding-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(15, 20, 30, 0.85);
  backdrop-filter: blur(6px);
  animation: fadeIn 0.3s ease;
}

.onboarding-modal {
  position: relative;
  width: min(100%, 520px);
  padding: 48px 40px 32px;
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 30px 100px rgba(0, 0, 0, 0.4);
  animation: slideUp 0.4s cubic-bezier(0.22, 1, 0.36, 1);
}

.skip-btn {
  position: absolute;
  top: 16px;
  right: 20px;
  padding: 6px 12px;
  color: #9aa3af;
  font-size: 12px;
  font-weight: 700;
  background: transparent;
  border: 0;
  border-radius: 6px;
  cursor: pointer;
}
.skip-btn:hover { color: #5d6675; background: #f5f5f7; }

.onboarding-content { text-align: center; }

.onboarding-icon {
  display: inline-grid;
  width: 80px;
  height: 80px;
  margin-bottom: 24px;
  place-items: center;
  font-size: 40px;
  background: linear-gradient(135deg, #e9e7ff 0%, #f3f1ff 100%);
  border-radius: 50%;
  animation: bounce 0.6s ease;
}

.onboarding-content h2 {
  margin: 0 0 12px;
  color: #293140;
  font: 800 24px 'Manrope', sans-serif;
  letter-spacing: -0.03em;
}

.onboarding-content p {
  margin: 0;
  color: #7d8796;
  font-size: 14px;
  line-height: 1.6;
}

.progress-dots {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin: 32px 0 24px;
}

.progress-dots span {
  width: 8px;
  height: 8px;
  background: #e7eaf0;
  border-radius: 50%;
  transition: all 0.3s ease;
}
.progress-dots span.active {
  width: 24px;
  background: #786be7;
  border-radius: 99px;
}
.progress-dots span.done { background: #786be7; opacity: 0.5; }

.onboarding-actions {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.btn-primary, .btn-secondary {
  padding: 12px 24px;
  font-size: 13px;
  font-weight: 700;
  border-radius: 8px;
  cursor: pointer;
  border: 0;
  transition: all 0.2s ease;
}

.btn-primary {
  color: #fff;
  background: #786be7;
}
.btn-primary:hover { background: #5f54c8; transform: translateY(-1px); }

.btn-secondary {
  color: #4c5666;
  background: #fff;
  border: 1px solid #e7eaf0;
}
.btn-secondary:hover { background: #f8f9fc; }

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
@keyframes slideUp {
  from { opacity: 0; transform: translateY(30px) scale(0.96); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
@keyframes bounce {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.15); }
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  .onboarding-modal { background: #1e2530; color: #f1f5f9; }
  .onboarding-content h2 { color: #f1f5f9; }
  .onboarding-content p { color: #9aa3af; }
}
</style>
