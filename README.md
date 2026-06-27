# Cosmic Forge

Ein Incremental Roguelite im Browser — passives Ressourcen-Management trifft auf aktive Runs durch prozedural skalierte Dungeons.

**[🎮 Jetzt spielen](https://danielzaiser91.github.io/cosmic-forge/)**

---

## Spielprinzip

Das Spiel besteht aus zwei Schichten:

**Idle Phase** — Baue Gebäude, kaufe Upgrades, sammle Ressourcen passiv. Ziel: die dritte Ressource auf den Prestige-Schwellwert bringen.

**Prestige Run** — 5 Räume + Boss, rundenbasierter Kampf mit Telegraph-System. Sieg = Relikt + nächste Prestige-Stufe.

**Ascension** — 3 Prestige-Stufen (Miner → Alchemist → Mage) ergeben eine Ascension. Vollständiger Reset, aber permanenter +10% Produktionsbonus pro Ascension.

## Progression

| Ascension | Unlock |
|-----------|--------|
| 2 | 4. Gebäude pro Stufe |
| 5 | 4. Upgrade + Gegner-Spike |
| 10 | 5. Gebäude + weiterer Spike |
| 20 | 5. Upgrade + Prestige-Ziele −25% · Cosmic Score aktiv |

## Tech Stack

- **Engine:** Godot 4 (GDScript, UI vollständig programmatisch)
- **Deploy:** GitHub Actions → GitHub Pages (Web Export)
- **Save:** JSON in `user://`, automatisch alle 30s, versioniert mit Migration
- **Notifications:** Discord Webhook via GitHub Actions nach jedem Deploy

## Entwicklung

```bash
# Repo klonen
git clone https://github.com/danielzaiser91/cosmic-forge.git

# In Godot 4 öffnen und F5 drücken
```

Deploy erfolgt automatisch bei jedem Push auf `main` (nur wenn Spiel-Dateien geändert wurden).
