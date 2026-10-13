# 🔐 Dossier Sécurité — TIME MANAGER THJ

Ce dossier centralise toute la documentation et les outils de test de sécurité du projet.

## Structure

```
security/
├── WRITEUP_MOBILE_SECURITY.md   # Writeup complet des 3 failles mobiles
├── README.md                    # Ce fichier
├── scripts/
│   ├── test_m1_localStorage.sh  # Test faille M1 (JWT dans localStorage)
│   └── test_m2_m3_network.sh    # Test failles M2 (JWT body) + M3 (port 4000)
└── reports/                     # Rapports générés automatiquement (gitignored)
    └── report_*.txt
```

## Failles couvertes

| ID | Description | Script de test |
|----|-------------|----------------|
| **M1** | JWT stocké dans `localStorage` (fallback non sécurisé) | `test_m1_localStorage.sh` |
| **M2** | JWT transmis dans le corps JSON de la réponse | `test_m2_m3_network.sh` |
| **M3** | Port 4000 exposé directement (contournement Nginx) | `test_m2_m3_network.sh` |

## Usage rapide

```bash
# Tester M1 (analyse statique du bundle mobile)
bash security/scripts/test_m1_localStorage.sh

# Tester M2 + M3 (statique + réseau + headers)
bash security/scripts/test_m2_m3_network.sh

# Tout tester d'un coup
bash security/scripts/test_m1_localStorage.sh && bash security/scripts/test_m2_m3_network.sh
```

Les rapports sont sauvegardés dans `security/reports/` avec horodatage.

## Statut actuel (commit `8f0b5fb`)

| Test | Résultat |
|------|----------|
| `test_m1_localStorage.sh` | ✅ 10 PASS / 0 FAIL |
| `test_m2_m3_network.sh` | ✅ 13 PASS / 0 FAIL |

→ Voir le [writeup complet](WRITEUP_MOBILE_SECURITY.md) pour les détails techniques.
