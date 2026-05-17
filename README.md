# OnePlus Debloater Script — v2.0

> **Fork v2.0** : refactor complet pour **OnePlus 15 / OxygenOS 16** avec détection automatique de device, mode disable (réversible), categories, dry-run, restore, et bien plus.

![OnePlus 15](https://img.shields.io/badge/OnePlus-15-eb0028) ![OxygenOS 16](https://img.shields.io/badge/OxygenOS-16-eb0028) ![No Root](https://img.shields.io/badge/Root-Not%20Required-3ecf8e) ![Bash](https://img.shields.io/badge/Bash-v2.0-blue)

## Pourquoi cette v2.0 ?

L'original (par [ronellsalunke](https://github.com/ronellsalunke/OnePlus-Debloater-Script)) date d'OxygenOS 9-10 et fait un `pm uninstall` direct sur une liste figée. Bien à l'époque, mais en 2026 :

- OxygenOS 16 a une **nouvelle famille de packages OPlus/ColorOS** (préfixes `com.oplus.*`, `com.coloros.*`, `com.heytap.*`)
- OnePlus 15 a son propre code device (`CPH2747` / `OP611FL1`)
- Faire un `pm uninstall` est **irréversible sans factory reset** — `pm disable-user` est plus sage
- Les utilisateurs veulent du **dry-run**, des catégories, et de la traçabilité (logs)

## Nouveautés v2.0

| Feature | v1 original | **v2.0 (this fork)** |
|---|---|---|
| Détection device + OS | non | **oui** OnePlus 15/13, OOS 15/16 |
| Mode disable (réversible) | non | **oui** par défaut |
| Mode uninstall | oui | oui via `--uninstall` |
| Mode restore | non | **oui** `--restore` |
| Dry-run | non | **oui** `--dry-run` |
| Catégories sélectionnables | non | **oui** 7 catégories |
| Multi-device targeting | non | **oui** `--serial` |
| Logs horodatés | non | **oui** auto |
| Confirmation interactive | non | **oui** par catégorie |
| Mode non-interactif | non | **oui** `--yes` |
| Couleur + UI clean | non | **oui** |
| OOS 16 / OnePlus 15 packages | non | **oui** validé mai 2026 |

## Pré-requis

1. **ADB / Platform Tools** : [télécharger ici](https://developer.android.com/studio/releases/platform-tools) ou via Homebrew : `brew install --cask android-platform-tools`
2. **Débogage USB** activé sur le téléphone : `Paramètres > À propos > Numéro de version` (tap 7×), puis `Paramètres > Système > Options développeur > Débogage USB`
3. **Autoriser** l'ordinateur dans le popup ADB sur le téléphone à la 1ʳᵉ connexion

## Utilisation rapide

```bash
git clone https://github.com/radnou/OnePlus-Debloater-Script.git
cd OnePlus-Debloater-Script
chmod +x debloat.sh

# Voir ce qui serait fait (recommandé en 1er)
./debloat.sh --dry-run

# Mode safe : désactive (réversible)
./debloat.sh

# Ne traiter que 2 catégories
./debloat.sh meta google-legacy

# Mode total non-interactif (CI/scripts)
./debloat.sh --yes all-safe

# Tout restaurer
./debloat.sh --restore
```

## Catégories disponibles

| Catégorie | Packages | Description |
|---|---|---|
| `meta` | 3-5 | Facebook / Meta bloat silencieux |
| `google-legacy` | 4 | Google Duo, Talkback, Android Auto, Print |
| `oplus-pub` | 3 | Atlas, ContentPortal, PsCanvas (pub OPlus) |
| `coloros` | 8 | ColorOS legacy : Weather, Compass, etc. |
| `heytap` | 3 | Accessory, Pictorial, Browser HeyTap |
| `oneplus-extra` | 6-8 | Note, BrickMode, Store, IR App |
| `google-health` | 2 | Health Connect (si Apple Health/Strava utilisés) |

Total **≈ 28-32 packages** safe à neutraliser selon votre device.

## Options complètes

```
--disable      Désactive (réversible, RECOMMANDÉ, défaut)
--uninstall    Désinstalle --user 0 (factory reset pour restaurer)
--restore      Réactive/réinstalle les packages
--dry-run      Affiche sans rien faire
--yes          Skip confirmations
--serial XYZ   Cible un device ADB spécifique
--log FILE     Path du log (défaut: ./debloat-TIMESTAMP.log)
--list         Liste les catégories disponibles
-h, --help     Aide
```

## Devices testés

| Device | Code | OxygenOS | Status |
|---|---|---|---|
| **OnePlus 15** EEA | CPH2747 / OP611FL1 | **16** | ✅ Validé 2026-05 |
| OnePlus 13 | CPH2649 / OP583DL1 | 15+ | ✅ Compatible |
| Autres OnePlus 11/12 | divers | 14+ | ⚠️ Partiel (packages legacy) |

## Sécurité — packages NE JAMAIS toucher

Le script ne touche jamais aux packages critiques :

- `com.oplus.systemui*` (SystemUI core)
- `com.oplus.customize*` (personnalisation core)
- `com.oplus.framework_*` (overlays framework)
- `com.android.phone` / `com.android.telephony*`
- `com.android.bluetooth`
- `com.oplus.aimemory` (AI cache perf)
- `com.android.keyguard` (lockscreen)
- `com.oplus.biometric*` (empreinte + face unlock)
- `com.qualcomm.*` (drivers SoC)

## Restauration totale

```bash
./debloat.sh --restore                       # toutes catégories
./debloat.sh --restore meta google-legacy    # restaurer 2 catégories
```

Ou manuellement :

```bash
adb shell cmd package install-existing <package_name>
adb shell pm enable <package_name>
```

## Roadmap

- [ ] Add detection: OnePlus 16 / OnePlus Open / Nord
- [ ] Add categories: `google-extra`, `samsung-bloat` (pour devices unifiés)
- [ ] CSV export des actions
- [ ] Mode interactif checklist-style (whiptail/dialog)
- [ ] Migration vers Python (gestion plus propre des erreurs)
- [ ] Support Magisk hide pour les packages non-désactivables sans root
- [ ] Module Shizuku natif (sans Mac)

## Disclaimer

Use at your own risk. Le mode `--disable` est 100 % réversible via `--restore` ou factory reset. Le mode `--uninstall` n'est pas vraiment irréversible (factory reset les fait revenir), mais nécessite un effort de restauration. Aucune garantie sur les comportements OS après debloat — testez catégorie par catégorie.

## Contributing

PRs welcome ! Particulièrement :
- Nouvelles entrées de packages OOS 16/17 testées
- Support d'autres devices OnePlus (validé via getprop)
- Traduction du README en EN / DE / etc.

## License

MIT — fork de [ronellsalunke/OnePlus-Debloater-Script](https://github.com/ronellsalunke/OnePlus-Debloater-Script).
