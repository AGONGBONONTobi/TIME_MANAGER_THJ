<script>
import cityImage from '../assets/gotham.jpg'

export default {
  name: 'AuthShell',
  props: {
    eyebrow: { type: String, default: 'ESPACE INTERNE' },
    title: { type: String, required: true },
    description: { type: String, required: true }
  },
  data() {
    return { cityImage }
  }
}
</script>

<template>
  <main class="auth-page">
    <section class="auth-form-side">
      <div class="auth-brand" aria-label="Time Manager">
        <span class="auth-brand-mark">TM</span>
        <span>Time Manager</span>
      </div>

      <div class="auth-form-content">
        <p class="auth-eyebrow">{{ eyebrow }}</p>
        <h1>{{ title }}</h1>
        <p class="auth-description">{{ description }}</p>
        <slot />
      </div>

      <p class="auth-legal">Accès réservé aux collaborateurs de l'entreprise.</p>
    </section>

    <aside class="auth-city-side" :style="{ backgroundImage: `url(${cityImage})` }" aria-label="Vue de Gotham City">
      <div class="auth-city-overlay"></div>
      <div class="auth-city-content">
        <p class="auth-city-kicker">GOTHAM CITY · OPERATIONS</p>
        <h2>Chaque minute compte.</h2>
        <p>Un espace de travail simple pour suivre vos horaires et garder le rythme de vos équipes.</p>
        <div class="auth-city-caption">
          <span class="caption-line"></span>
          <span>GOTHAM CITY</span>
        </div>
      </div>
    </aside>
  </main>
</template>

<style scoped>
.auth-page {
  display: grid;
  grid-template-columns: minmax(390px, 0.86fr) minmax(480px, 1.14fr);
  min-height: 100vh;
  padding: 18px;
  color: #17202c;
  background: #f4f6f8;
  font-family: 'DM Sans', sans-serif;
}

.auth-form-side {
  display: flex;
  flex-direction: column;
  min-width: 0;
  padding: clamp(24px, 5vw, 76px) clamp(24px, 7vw, 108px);
  background: #fff;
  border-radius: 24px 0 0 24px;
}

.auth-brand {
  display: flex;
  align-items: center;
  gap: 11px;
  color: #182333;
  font-family: 'Manrope', sans-serif;
  font-size: 15px;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.auth-brand-mark {
  display: grid;
  width: 35px;
  height: 35px;
  place-items: center;
  color: #fff;
  background: #1e2b3a;
  border-radius: 11px;
  font-size: 10px;
  letter-spacing: 0.04em;
}

.auth-form-content {
  width: min(100%, 410px);
  margin: auto 0;
  padding: 54px 0;
}

.auth-eyebrow,
.auth-city-kicker {
  margin: 0 0 16px;
  color: #748093;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.16em;
}

.auth-form-content h1 {
  margin: 0;
  color: #17202c;
  font-family: 'Manrope', sans-serif;
  font-size: clamp(2.5rem, 4vw, 4.4rem);
  font-weight: 800;
  letter-spacing: -0.075em;
  line-height: 0.98;
}

.auth-description {
  max-width: 36ch;
  margin: 20px 0 38px;
  color: #788494;
  font-size: 14px;
  line-height: 1.7;
}

.auth-legal {
  margin: 0;
  color: #a4adba;
  font-size: 11px;
}

.auth-city-side {
  position: relative;
  display: flex;
  min-height: 680px;
  overflow: hidden;
  color: #fff;
  background-color: #1d2d3c;
  background-position: center;
  background-size: cover;
  border-radius: 0 24px 24px 0;
}

.auth-city-overlay {
  position: absolute;
  inset: 0;
  background: rgba(15, 31, 43, 0.25);
}

.auth-city-content {
  position: relative;
  display: flex;
  align-self: flex-end;
  flex-direction: column;
  width: min(500px, 100%);
  margin: 0 0 54px 54px;
  padding: 26px 28px;
  background: rgba(17, 32, 45, 0.72);
  border: 1px solid rgba(255, 255, 255, 0.22);
  border-radius: 18px;
  backdrop-filter: blur(10px);
}

.auth-city-kicker { margin-bottom: 14px; color: #b9d3de; }
.auth-city-content h2 { margin: 0; font: 800 clamp(2rem, 4vw, 3.6rem) / 0.98 'Manrope', sans-serif; letter-spacing: -0.07em; }
.auth-city-content > p:not(.auth-city-kicker) { max-width: 38ch; margin: 18px 0 0; color: rgba(255, 255, 255, 0.76); font-size: 13px; line-height: 1.6; }
.auth-city-caption { display: flex; align-items: center; gap: 10px; margin-top: 28px; color: #fff; font-size: 9px; font-weight: 800; letter-spacing: 0.14em; }
.caption-line { width: 30px; height: 1px; background: #c4e2ed; }

:deep(.auth-form) { display: grid; gap: 18px; }
:deep(.auth-field) { display: grid; gap: 8px; }
:deep(.auth-field-label) { color: #344152; font-size: 12px; font-weight: 700; }
:deep(.auth-input-wrap) { position: relative; display: flex; align-items: center; border: 1px solid #dfe5eb; border-radius: 13px; background: #fbfcfd; transition: border-color 0.2s ease, box-shadow 0.2s ease, background 0.2s ease; }
:deep(.auth-input-wrap:focus-within) { background: #fff; border-color: #76a5b8; box-shadow: 0 0 0 4px rgba(101, 163, 183, 0.13); }
:deep(.auth-input) { width: 100%; min-height: 50px; padding: 0 15px; color: #182333; background: transparent; border: 0; border-radius: inherit; outline: 0; font-size: 13px; }
:deep(.auth-input::placeholder) { color: #adb7c1; }
:deep(.auth-password-toggle) { margin-right: 10px; padding: 6px; color: #80909d; background: transparent; border: 0; cursor: pointer; font-size: 11px; font-weight: 700; }
:deep(.auth-password-toggle:hover) { color: #1f6072; }
:deep(.auth-submit) { min-height: 52px; margin-top: 4px; color: #fff; background: #1e2b3a; border: 0; border-radius: 13px; box-shadow: 0 10px 20px rgba(30, 43, 58, 0.18); cursor: pointer; font-size: 13px; font-weight: 800; transition: transform 0.2s ease, background 0.2s ease, box-shadow 0.2s ease; }
:deep(.auth-submit:hover:not(:disabled)) { background: #2d5263; box-shadow: 0 14px 26px rgba(30, 43, 58, 0.22); transform: translateY(-1px); }
:deep(.auth-submit:disabled) { cursor: wait; opacity: 0.65; }
:deep(.auth-error), :deep(.auth-success) { margin: 0; padding: 11px 13px; border-radius: 10px; font-size: 12px; line-height: 1.5; }
:deep(.auth-error) { color: #8a3030; background: #fff2f1; border: 1px solid #f1c8c5; }
:deep(.auth-success) { color: #216642; background: #eef9f1; border: 1px solid #c3e7ca; }
:deep(.auth-switch) { margin: 5px 0 0; color: #82909d; font-size: 12px; text-align: center; }
:deep(.auth-switch a) { color: #27697c; font-weight: 800; text-decoration: none; }
:deep(.auth-switch a:hover) { text-decoration: underline; }

@media (max-width: 900px) {
  .auth-page { grid-template-columns: 1fr; padding: 0; }
  .auth-form-side { min-height: 100vh; border-radius: 0; }
  .auth-city-side { display: none; }
}

@media (prefers-reduced-motion: reduce) {
  :deep(.auth-submit) { transition: none; }
}
</style>
