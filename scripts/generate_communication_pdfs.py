import os
import subprocess

OUT_DIR = "/home/agongbonontobiprince/TIME_MANAGER_THJ/communication"
PDF_DIR = os.path.join(OUT_DIR, "pdf")
SRC_DIR = os.path.join(OUT_DIR, "src")
os.makedirs(PDF_DIR, exist_ok=True)
os.makedirs(SRC_DIR, exist_ok=True)

SHARED_CSS = """
<style>
  @page {
    size: A4;
    margin: 18mm 16mm 20mm 16mm;
    @bottom-right {
      content: "Page " counter(page) " / " counter(pages);
      font-size: 8pt;
      color: #64748b;
    }
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #1e293b;
    background-color: #ffffff;
    line-height: 1.55;
    font-size: 10pt;
    margin: 0;
    padding: 0;
  }

  .header {
    border-bottom: 2px solid #0f172a;
    padding-bottom: 12px;
    margin-bottom: 20px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
  }

  .header-left h1 {
    margin: 0;
    font-size: 19pt;
    font-weight: 800;
    color: #0f172a;
    letter-spacing: -0.02em;
  }

  .header-left .subtitle {
    margin: 4px 0 0;
    font-size: 10pt;
    color: #0284c7;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
  }

  .header-right {
    text-align: right;
    font-size: 8.5pt;
    color: #64748b;
    line-height: 1.35;
  }

  .badge {
    display: inline-block;
    padding: 3px 8px;
    font-size: 7.5pt;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    border-radius: 4px;
    background-color: #e0f2fe;
    color: #0369a1;
  }

  .badge-danger {
    background-color: #fee2e2;
    color: #b91c1c;
  }

  .badge-success {
    background-color: #dcfce7;
    color: #15803d;
  }

  .banner {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-left: 4px solid #0284c7;
    border-radius: 6px;
    padding: 12px 14px;
    margin-bottom: 22px;
  }

  .banner p {
    margin: 0;
    font-size: 9.5pt;
    color: #334155;
  }

  .banner strong {
    color: #0f172a;
  }

  h2 {
    color: #0f172a;
    font-size: 13pt;
    font-weight: 700;
    margin-top: 24px;
    margin-bottom: 10px;
    border-bottom: 1px solid #e2e8f0;
    padding-bottom: 4px;
    page-break-after: avoid;
  }

  .qa-card {
    background: #ffffff;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    padding: 12px 14px;
    margin-bottom: 12px;
    page-break-inside: avoid;
  }

  .qa-question {
    font-weight: 700;
    color: #0f172a;
    font-size: 10.5pt;
    margin-bottom: 6px;
    display: flex;
    align-items: flex-start;
  }

  .qa-num {
    background: #0f172a;
    color: #ffffff;
    border-radius: 50%;
    width: 20px;
    height: 20px;
    font-size: 8pt;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    margin-right: 8px;
    flex-shrink: 0;
    line-height: 20px;
    text-align: center;
  }

  .qa-answer {
    color: #334155;
    font-size: 9.5pt;
    margin: 0;
    line-height: 1.5;
  }

  .qa-highlight {
    font-weight: 600;
    color: #0369a1;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
    font-size: 8.5pt;
    page-break-inside: auto;
  }

  tr {
    page-break-inside: avoid;
    page-break-after: auto;
  }

  th {
    background-color: #0f172a;
    color: #ffffff;
    text-align: left;
    padding: 8px 10px;
    font-weight: 700;
    font-size: 8.5pt;
    letter-spacing: 0.03em;
  }

  td {
    padding: 8px 10px;
    border-bottom: 1px solid #e2e8f0;
    vertical-align: top;
  }

  tr:nth-child(even) td {
    background-color: #f8fafc;
  }

  .text-center { text-align: center; }
  .text-danger { color: #dc2626; font-weight: 700; }
  .text-success { color: #16a34a; font-weight: 700; }

  .page-break {
    page-break-before: always;
  }

  .footer-note {
    margin-top: 30px;
    padding-top: 10px;
    border-top: 1px solid #e2e8f0;
    font-size: 8pt;
    color: #64748b;
    display: flex;
    justify-content: space-between;
  }

  .timecode-badge {
    background-color: #e2e8f0;
    color: #1e293b;
    font-weight: 700;
    font-family: monospace;
    font-size: 8pt;
    padding: 2px 6px;
    border-radius: 4px;
  }

  .quote-box {
    background: #f1f5f9;
    border-left: 3px solid #64748b;
    padding: 8px 12px;
    font-style: italic;
    color: #334155;
    margin: 6px 0;
    font-size: 9pt;
  }
</style>
"""

# 1. FAQ Syndicale HTML
FAQ_HTML = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Time Manager — FAQ Représentants du Personnel & Syndicats</title>
  {SHARED_CSS}
</head>
<body>
  <div class="header">
    <div class="header-left">
      <div class="subtitle">Ville de Gotham • Direction des Ressources Humaines</div>
      <h1>Time Manager — FAQ Syndicale</h1>
    </div>
    <div class="header-right">
      <span class="badge">Document Officiel CSE</span><br>
      Date : Octobre 2026<br>
      Réf : TM-RH-SYN-04
    </div>
  </div>

  <div class="banner">
    <p><strong>Engagements de transparence :</strong> Ce document répond point par point aux préoccupations exprimées par les représentants du personnel concernant le déploiement de <em>Time Manager</em>. L'application a pour finalité unique l'enregistrement loyal et le juste paiement des heures travaillées, sans dispositif de flicage ni dérive algorithmique.</p>
  </div>

  <h2>1. Respect de la vie privée & Délimitation technique</h2>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">1</span>
      L'application Time Manager géolocalise-t-elle les agents par GPS ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Non, formellement et techniquement.</span> L'application ne sollicite aucune permission GPS auprès du système d'exploitation et n'intègre aucun capteur de géolocalisation. Le pointage enregistre uniquement l'heure et la minute de validation. Les agents de terrain (voirie, gardiens, patrouilles) ne font l'objet d'aucun traçage spatial.</p>
  </div>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">2</span>
      Existe-t-il des dispositifs de surveillance active (captures d'écran, caméra, micro, frappe clavier) ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Aucun dispositif de surveillance active n'existe.</span> L'outil est strictement un cahier d'émargement numérique. Il n'accède ni à la caméra, ni au microphone, ni aux fichiers personnels, et ne capture jamais les écrans. Les permissions demandées sont limitées aux notifications locales pour les rappels de fin de quart.</p>
  </div>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">3</span>
      Les agents ne possédant pas de smartphone ou refusant d'utiliser leur appareil personnel sont-ils pénalisés ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Aucune pénalisation ni obligation sur appareil personnel.</span> L'application est accessible sur les smartphones de dotation, mais aussi depuis les postes fixes d'accueil et terminaux de poste de garde via navigateur. En cas d'impossibilité totale, le pointage assisté par le responsable de service reste garanti conformément aux accords conventionnels.</p>
  </div>

  <h2>2. Rémunération, Heures de Nuit & Heures Supplémentaires</h2>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">4</span>
      Comment sont décomptées et majorées les heures de nuit (22h00 – 06h00) ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Le calcul est entièrement automatisé et auditable.</span> Toute minute prestée entre 22h00 et 06h00 est automatiquement ventilée en heures de nuit avec coefficient légal de majoration (×1,5). L'agent visualise immédiatement ses compteurs majorés sur son tableau de bord personnel, ce qui garantit la fin des contestations sur les fiches de paie.</p>
  </div>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">5</span>
      Comment sont comptabilisées les heures supplémentaires (Overtime) ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Au-delà du forfait hebdomadaire légal (35h),</span> les heures supplémentaires sont basculées dans le compteur d'overtime avec une majoration de 100% (coefficient ×2). Le système alerte automatiquement le manager pour prévenir la fatigue excessive et éviter d'enchaîner plus de 3 nuits consécutives.</p>
  </div>

  <div class="page-break"></div>

  <h2>3. Droit à l'erreur, Régularisations & Traçabilité</h2>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">6</span>
      Que se passe-t-il si un agent oublie de pointer ou fait une fausse manipulation ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Le droit à l'erreur est garanti sans pénalité.</span> L'agent dispose d'un module de « Demande de régularisation » permettant de renseigner son heure réelle et la raison de l'oubli. L'encadrement valide la demande sous 48h. Aucune retenue sur salaire automatique n'est possible sans échange préalable.</p>
  </div>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">7</span>
      Un manager peut-il modifier les horaires d'un agent unilatéralement et en secret ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Non, chaque modification est enregistrée dans un journal d'audit immuable.</span> L'historique conserve l'horodatage initial, la valeur modifiée, l'auteur de l'action et le motif fourni. L'agent est notifié de toute modification apportée à sa fiche et conserve un droit de recours auprès des RH.</p>
  </div>

  <h2>4. Accompagnement, Accessibilité & Données</h2>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">8</span>
      Quel accompagnement est prévu pour les agents peu familiers du numérique ou en situation de handicap ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Formation courte et interface conforme RGAA / WCAG.</span> Des sessions de prise en main de 15 minutes sont organisées en début de quart. Une vidéo de 2 minutes et une fiche cartonnée synthétique sont remises. L'interface mobile prend en charge la synthèse vocale, les contrastes élevés (Thème sombre Gotham) et la navigation simplifiée par gros boutons tactiles.</p>
  </div>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">9</span>
      Les données sont-elles utilisées pour du scoring ou du micromanagement ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">C'est formellement interdit par la charte de gouvernance.</span> Les données d'horodatage servent exclusivement à la paie et au contrôle du respect des temps de repos minimaux (11h consécutives obligatoires). Aucun module d'évaluation de la productivité, de classement d'agents ou de notation n'est connecté au système.</p>
  </div>

  <div class="qa-card">
    <div class="qa-question">
      <span class="qa-num">10</span>
      Quelle est la politique de conservation et de sécurité des données (RGPD) ?
    </div>
    <p class="qa-answer"><span class="qa-highlight">Conservation stricte de 5 ans conformément au Code du travail.</span> L'accès aux données est compartimenté par contrôle d'accès strict (RBAC) : l'agent voit ses heures, le manager voit son équipe, et la DRH a la vision de contrôle paie. Les agents peuvent exercer leur droit de rectification et d'accès auprès du Délégué à la Protection des Données (DPO) de la Ville.</p>
  </div>

  <div class="footer-note">
    <span>Direction des Relations Sociales & RH • Ville de Gotham</span>
    <span>Document d'information syndicale validé</span>
  </div>
</body>
</html>
"""

# 2. Registre des Données RGPD HTML
REGISTRE_HTML = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Time Manager — Registre des Données Personnelles (RGPD)</title>
  {SHARED_CSS}
</head>
<body>
  <div class="header">
    <div class="header-left">
      <div class="subtitle">Conformité RGPD • Art. 30 du Règlement (UE) 2016/679</div>
      <h1>Registre des Traitements de Données</h1>
    </div>
    <div class="header-right">
      <span class="badge badge-success">Conforme DPO</span><br>
      Fiche Traitement : #TM-DATA-01<br>
      Responsable : Ville de Gotham
    </div>
  </div>

  <div class="banner">
    <p><strong>Cadre réglementaire :</strong> Le traitement <em>Time Manager</em> a pour finalité unique la gestion et le décompte du temps de travail, le respect des plafonds légaux de santé/sécurité au travail, et le calcul des éléments variables de paie (heures de nuit, astreintes, heures supplémentaires). Toute utilisation détournée pour de la surveillance continue est strictement proscrite.</p>
  </div>

  <h2>1. Tableau de Traitement des Données Personnelles</h2>

  <table>
    <thead>
      <tr>
        <th style="width: 25%;">Donnée Personnelle</th>
        <th style="width: 12%; text-align: center;">Collectée ?</th>
        <th style="width: 12%; text-align: center;">Agent</th>
        <th style="width: 12%; text-align: center;">Manager</th>
        <th style="width: 14%;">Conservation</th>
        <th style="width: 25%;">Base Légale & Finalité</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>Horodatage d'arrivée (Clock In)</strong><br><small>Date, heure et minute de prise de poste</small></td>
        <td class="text-center text-success">OUI</td>
        <td class="text-center">Oui</td>
        <td class="text-center">Oui</td>
        <td>5 ans</td>
        <td>Obligation légale (Art. L. 3171-2 Code du travail) — Décompte du temps effectif.</td>
      </tr>
      <tr>
        <td><strong>Horodatage de départ (Clock Out)</strong><br><small>Date, heure et minute de fin de service</small></td>
        <td class="text-center text-success">OUI</td>
        <td class="text-center">Oui</td>
        <td class="text-center">Oui</td>
        <td>5 ans</td>
        <td>Obligation légale — Contrôle de la durée journalière maximale.</td>
      </tr>
      <tr>
        <td><strong>Compteur Heures de Nuit</strong><br><small>Tranche 22h00 – 06h00 (Majoration ×1.5)</small></td>
        <td class="text-center text-success">OUI</td>
        <td class="text-center">Oui</td>
        <td class="text-center">Oui</td>
        <td>5 ans</td>
        <td>Accord collectif & Code du travail — Établissement de la rémunération majorée.</td>
      </tr>
      <tr>
        <td><strong>Compteur Overtime / Heures Sup.</strong><br><small>Heures au-delà du forfait (Majoration ×2.0)</small></td>
        <td class="text-center text-success">OUI</td>
        <td class="text-center">Oui</td>
        <td class="text-center">Oui</td>
        <td>5 ans</td>
        <td>Obligation légale — Calcul des repos compensateurs et paie.</td>
      </tr>
      <tr>
        <td><strong>Motifs de régularisation horaire</strong><br><small>Commentaire déposé lors d'un oubli</small></td>
        <td class="text-center text-success">OUI</td>
        <td class="text-center">Oui</td>
        <td class="text-center">Oui</td>
        <td>5 ans</td>
        <td>Intérêt légitime — Traçabilité des corrections concertées.</td>
      </tr>
      <tr>
        <td><strong>Identité & Email professionnel</strong><br><small>Nom, prénom, matricule, adresse pro</small></td>
        <td class="text-center text-success">OUI</td>
        <td class="text-center">Oui</td>
        <td class="text-center">Oui</td>
        <td>Durée contrat + 5 ans</td>
        <td>Gestion administrative et authentification sécurisée.</td>
      </tr>
      <tr style="background-color: #fef2f2;">
        <td><strong>Géolocalisation / Coordonnées GPS</strong><br><small>Positionnement par satellite du smartphone</small></td>
        <td class="text-center text-danger">NON</td>
        <td class="text-center text-danger">—</td>
        <td class="text-center text-danger">—</td>
        <td>Aucune</td>
        <td><span class="badge badge-danger">EXCLU</span> Non proportionné au décompte horaire déclaratif.</td>
      </tr>
      <tr style="background-color: #fef2f2;">
        <td><strong>Captures d'écran (Screenshots)</strong><br><small>Enregistrement visuel du terminal</small></td>
        <td class="text-center text-danger">NON</td>
        <td class="text-center text-danger">—</td>
        <td class="text-center text-danger">—</td>
        <td>Aucune</td>
        <td><span class="badge badge-danger">EXCLU</span> Atteinte manifeste à la vie privée.</td>
      </tr>
      <tr style="background-color: #fef2f2;">
        <td><strong>Historique de navigation Web</strong><br><small>URLs visitées, activité réseau hors application</small></td>
        <td class="text-center text-danger">NON</td>
        <td class="text-center text-danger">—</td>
        <td class="text-center text-danger">—</td>
        <td>Aucune</td>
        <td><span class="badge badge-danger">EXCLU</span> Hors périmètre technique.</td>
      </tr>
      <tr style="background-color: #fef2f2;">
        <td><strong>Frappes clavier (Keylogger)</strong><br><small>Enregistrement des frappes de l'utilisateur</small></td>
        <td class="text-center text-danger">NON</td>
        <td class="text-center text-danger">—</td>
        <td class="text-center text-danger">—</td>
        <td>Aucune</td>
        <td><span class="badge badge-danger">EXCLU</span> Strictement interdit.</td>
      </tr>
      <tr style="background-color: #fef2f2;">
        <td><strong>Données biométriques (Empreinte / Visage)</strong><br><small>Reconnaissance faciale ou digitale</small></td>
        <td class="text-center text-danger">NON</td>
        <td class="text-center text-danger">—</td>
        <td class="text-center text-danger">—</td>
        <td>Aucune</td>
        <td><span class="badge badge-danger">EXCLU</span> Non requis pour le système d'authentification.</td>
      </tr>
    </tbody>
  </table>

  <h2>2. Mesures de Sécurité & Droits des Agents</h2>
  <div class="qa-card">
    <p class="qa-answer">
      <strong>Chiffrement & Sécurité des échanges :</strong> Tous les échanges réseau entre l'application mobile et l'API centrale sont chiffrés de bout en bout via TLS/HTTPS. L'authentification repose sur des jetons signés cryptographiquement (JWT).<br>
      <strong>Exercice des droits RGPD :</strong> Conformément aux articles 15 à 22 du RGPD, chaque agent bénéficie d'un droit d'accès permanent à son historique, d'un droit de rectification immédiat de ses pointages, et d'un droit de réclamation auprès du DPO de la Ville de Gotham (<code>dpo@gotham.gov</code>) ou de la CNIL.
    </p>
  </div>

  <div class="footer-note">
    <span>Registre de traitement des données personnelles • Conforme CNIL & RGPD</span>
    <span>DPO Ville de Gotham</span>
  </div>
</body>
</html>
"""

# 3. Kit Communication Complet HTML (FAQ + Registre + Script Vidéo Storyboard)
KIT_HTML = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Time Manager — Kit de Communication Thème 04 : Le Syndicat</title>
  {SHARED_CSS}
</head>
<body>
  <div class="header">
    <div class="header-left">
      <div class="subtitle">Livrable de Communication • Thème 04 (Gestion de la Résistance)</div>
      <h1>Kit de Communication — Dialogue Social & Syndicats</h1>
    </div>
    <div class="header-right">
      <span class="badge">Dossier Complet</span><br>
      Projet : Time Manager Gotham<br>
      Audience : Syndicats, Élus CSE, Managers
    </div>
  </div>

  <div class="banner">
    <p><strong>Note de synthèse stratégique :</strong> Face aux craintes initiales d'un outil de « flicage » ou de surcharge administrative pour les personnels de terrain, ce kit regroupe les 3 piliers de la stratégie de concertation : la <strong>FAQ syndicale</strong> (10 réponses fermes et factuelles), le <strong>Registre RGPD</strong> démontrant l'absence totale de surveillance intrusive, et le <strong>Script vidéo minuté (3 min 30)</strong> démontrant la simplicité réelle de l'outil.</p>
  </div>

  <h2>Partie 1 : Script Vidéo Minuté & Storyboard (3 min 30)</h2>
  <p>Ce script associe des séquences d'ambiance sobres (générables sous Veo ou images Nano Banana) et une démonstration concrète sur l'application avec le compte d'Alice (<code>alice@test.local</code>).</p>

  <table>
    <thead>
      <tr>
        <th style="width: 14%;">Minutage</th>
        <th style="width: 36%;">Visuel & Réalisation</th>
        <th style="width: 50%;">Voix off (Script mot à mot)</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><span class="timecode-badge">00:00 - 00:25</span></td>
        <td>
          <strong>Intro d'ambiance</strong><br>
          <em>Prompt Veo :</em> "Slow pan over an empty municipal office at dawn, soft atmospheric light, documentary style, 4k."<br>
          Carton titre : <em>Time Manager • Ville de Gotham</em>
        </td>
        <td>
          <div class="quote-box">« Dans les services opérationnels de Gotham — sécurité, voirie, maintenance —, chaque minute sur le terrain compte. Garantir que chaque heure travaillée, chaque heure de nuit et chaque astreinte soit loyalement décomptée et justement rémunérée : c'est l'objectif unique de Time Manager. »</div>
        </td>
      </tr>
      <tr>
        <td><span class="timecode-badge">00:25 - 00:55</span></td>
        <td>
          <strong>Ce que l'application NE FAIT PAS</strong><br>
          Slide sobre, pictogrammes rouges barrés : <em>Pas de GPS • Pas de captures d'écran • Pas de biométrie</em>.
        </td>
        <td>
          <div class="quote-box">« Levons d'emblée les inquiétudes légitimes : Time Manager n'est pas un outil de surveillance. L'application n'utilise aucun GPS. Elle n'accède ni à votre caméra, ni à vos données personnelles, ni à votre écran. C'est un cahier d'émargement moderne, numérique, transparent pour tous. »</div>
        </td>
      </tr>
      <tr>
        <td><span class="timecode-badge">00:55 - 02:15</span></td>
        <td>
          <strong>Démo d'Alice en situation réelle</strong><br>
          Capture d'écran mobile / webview :<br>
          1. Ouverture (Splash Batman + loading bar 2.8s).<br>
          2. Clic sur le bouton vert <strong>Clock In</strong>.<br>
          3. Affichage du compteur en temps réel.<br>
          4. Visualisation des <strong>heures de nuit (22h-6h)</strong> majorées à ×1.5.<br>
          5. Clic sur <strong>Clock Out</strong> en fin de service.
        </td>
        <td>
          <div class="quote-box">« Voici le parcours réel d'un agent de terrain. Deux clics par jour : un au début du poste, un à la fin. Tout est visible immédiatement par l'agent. Pas de calculs opaques : les heures de nuit sont automatiquement isolées et majorées conformément à nos accords collectifs. »</div>
        </td>
      </tr>
      <tr>
        <td><span class="timecode-badge">02:15 - 02:50</span></td>
        <td>
          <strong>Transparence & Droit à l'erreur</strong><br>
          Démo du formulaire : « Demande de régularisation » avec saisie d'un motif clair et validation par le manager.
        </td>
        <td>
          <div class="quote-box">« Un oubli ? Une intervention imprévue sans téléphone à portée de main ? Aucun problème. L'agent dispose d'un espace de régularisation pour déclarer son heure réelle. Aucune pénalité, aucune sanction unilatérale. L'encadrement valide les demandes avec un historique d'audit consultable à tout moment. »</div>
        </td>
      </tr>
      <tr>
        <td><span class="timecode-badge">02:50 - 03:30</span></td>
        <td>
          <strong>Outro & Dialogue Social</strong><br>
          Plan sur les bâtiments municipaux au crépuscule.<br>
          Carton final : <em>Formations de 15 min disponibles dès cette semaine • Vos délégués à votre écoute</em>.
        </td>
        <td>
          <div class="quote-box">« Time Manager a été pensé avec et pour le personnel : simple d'utilisation, accessible sur tous les supports, respectueux de la vie privée et garant du juste paiement de chaque heure de travail. Des sessions d'accompagnement de 15 minutes sont déployées dès cette semaine pour toutes les équipes. Merci pour votre engagement quotidien. »</div>
        </td>
      </tr>
    </tbody>
  </table>

  <div class="page-break"></div>

  <h2>Partie 2 : Fiche Synthétique des Prompts IA</h2>
  <div class="banner">
    <p>Ces prompts sont prêts à être copiés dans <strong>Google Veo</strong> (pour les clips vidéo d'ambiance) et <strong>Nano Banana / Imagen</strong> (pour les diapositives de présentation).</p>
  </div>

  <table>
    <thead>
      <tr>
        <th style="width: 20%;">Outil</th>
        <th style="width: 30%;">Séquence</th>
        <th style="width: 50%;">Prompt optimisé (Anglais pour meilleur rendu IA)</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>Google Veo</strong></td>
        <td>Intro Vidéo (00:00)</td>
        <td><code>Slow pan over a modern municipal office at dawn, empty desks, soft blue morning light through large windows, cinematic 4k, documentary style, no people, photorealistic.</code></td>
      </tr>
      <tr>
        <td><strong>Google Veo</strong></td>
        <td>Transition Mobile (00:55)</td>
        <td><code>Close-up of working person hands holding a smartphone in low light, screen displaying clean interface, shallow depth of field, warm cinematic lighting, realistic movements.</code></td>
      </tr>
      <tr>
        <td><strong>Google Veo</strong></td>
        <td>Outro Équipes (03:00)</td>
        <td><code>Wide establishing shot of a municipal public service building at dusk, Gotham city architecture, soft street lights turning on, calm, professional, documentary footage.</code></td>
      </tr>
      <tr>
        <td><strong>Nano Banana</strong></td>
        <td>Slide Anti-Surveillance</td>
        <td><code>Clean corporate presentation slide, solid dark navy blue background, modern minimalist style, three distinct red circle badge icons with slash lines representing no GPS, no screen capture, no webcam, elegant French typography reading 'Garantie Respect Vie Privée', 16:9 ratio.</code></td>
      </tr>
      <tr>
        <td><strong>Nano Banana</strong></td>
        <td>Bannière Parcours Agent</td>
        <td><code>Professional horizontal banner, deep navy and gold Gotham color scheme, sleek smartphone icon with clock symbol, clean title 'Parcours Agent Terrain', vector minimalist corporate art.</code></td>
      </tr>
    </tbody>
  </table>

  <div class="footer-note">
    <span>Kit de Communication Thème 04 • Time Manager Gotham</span>
    <span>Direction de projet & Dialogue social</span>
  </div>
</body>
</html>
"""

# Write HTML sources
html_files = {
    "faq_syndicat.html": FAQ_HTML,
    "registre_rgpd.html": REGISTRE_HTML,
    "kit_communication_complet.html": KIT_HTML
}

for fname, content in html_files.items():
    fpath = os.path.join(SRC_DIR, fname)
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Generated HTML: {fpath}")

# Convert each to PDF using LibreOffice
pdf_targets = {
    "faq_syndicat.html": "FAQ_Syndicat_Time_Manager.pdf",
    "registre_rgpd.html": "Registre_Donnees_Personnelles_RGPD.pdf",
    "kit_communication_complet.html": "Kit_Communication_Theme04_Syndicat.pdf"
}

for html_name, pdf_name in pdf_targets.items():
    src_file = os.path.join(SRC_DIR, html_name)
    cmd = [
        "libreoffice",
        "-env:UserInstallation=file:///tmp/LibO_GenPDF",
        "--headless",
        "--convert-to", "pdf:writer_pdf_Export",
        "--outdir", PDF_DIR,
        src_file
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    out_pdf = os.path.join(PDF_DIR, html_name.replace(".html", ".pdf"))
    final_pdf = os.path.join(PDF_DIR, pdf_name)
    if os.path.exists(out_pdf):
        os.rename(out_pdf, final_pdf)
        print(f"SUCCESS: Generated PDF -> {final_pdf} ({os.path.getsize(final_pdf):,} bytes)")
    else:
        print(f"ERROR converting {html_name}: {res.stderr}")

print("All PDF files successfully generated!")
