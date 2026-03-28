---
name: scene-directives
description: Vollstaendige Spezifikation fuer Szenenanweisungen zur Steuerung von Hintergruenden, Figuren, Ausdruecken und Assets.
purpose_triggers:
  - mission_generation
  - new_mission
  - consequence
  - scene_update
  - choice_followup
  - night_cycle
  - teammate_interference
  - gloria_intervention
  - intro_story
  - prayer
---

# Szenenanweisungs-System

## Ueberblick

Szenenanweisungen steuern die visuelle Darstellung des Spiels. Fuegen Sie sie in Ihre Antwort ein, um Hintergruende, Charakterausdruecke und sichtbare Assets zu aktualisieren.

## Antwortformat

Ihre Antwort soll ZWEI Abschnitte haben:
1. Erzaehltext
2. Szenenanweisungen als JSON-Block fuer visuelle Aktualisierungen

```
[Hier steht der Erzaehltext...]

[SCENE_DIRECTIVES]
{
  "scene": {
    "background": "background_id",
    "atmosphere": "dark|mysterious|bright|tense",
    "lighting": "dim|bright|normal"
  },
  "characters": {
    "protagonist": {"expression": "neutral", "visible": true},
    "gloria": {"expression": "happy", "visible": true},
    "donkey": {"expression": "confused", "visible": false},
    "ark": {"expression": "thinking", "visible": false},
    "one": {"expression": "neutral", "visible": false},
    "teacher_chan": {"expression": "happy", "visible": false}
  },
  "assets": [
    {"id": "asset_id", "contextual_name": "Anzeigename", "description": "Kurze Beschreibung"}
  ],
  "mission_status": "ongoing|complete"
}
[/SCENE_DIRECTIVES]
```

## Verfuegbare Hintergruende

| ID | Beschreibung |
|----|--------------|
| default | Standard-Bueroraum |
| prayer | Gebets- oder Meditationsraum |
| forest | Waldszene im Freien |
| cave | Dunkle Hoehle |
| temple | Antiker Tempel |
| ruins | Zerstoerte Ruinen |
| laboratory | Labor |
| throne_room | Grosser Thronsaal |
| bridge | Bruecken- oder Uebergangsszene |
| portal_area | Magische Portalzone |
| water | Nahe Wasser oder Ozean |
| fire | Feuer- oder Vulkanbereich |
| garden | Ruhiger Garten |
| dungeon | Dunkles Verlies |
| crystal_cavern | Kristallgefuellte Hoehle |
| library | Antike Bibliothek |
| safe_zone | Geschuetzter Bereich |
| battlefield | Kampfzone |

## Verfuegbare Ausdruecke

Alle Figuren koennen diese expression-IDs verwenden:
- neutral
- happy
- sad
- angry
- confused
- shocked
- thinking
- embarrassed

## Charakter-IDs

| ID | Figur |
|----|-------|
| protagonist | Die Spielerfigur |
| gloria | Gloria |
| donkey | Donkey |
| ark | ARK |
| one | One |
| teacher_chan | Teacher Chan |

## NPC-Portraets

Verwenden Sie fuer Nebenfiguren das assets-Array mit der Kategorie "npc":

```json
"assets": [
  {"category": "npc", "id": "generic_guard", "slot": 1, "contextual_name": "Torwache"}
]
```

Verfuegbare NPC-IDs:
- generic_villager_male
- generic_villager_female
- generic_guard
- generic_merchant
- generic_elder
- generic_child
- generic_priest
- generic_scientist

Slots: 1, 2 oder 3

## Richtlinien

1. Fuegen Sie Szenenanweisungen immer nach dem Erzaehltext ein.
2. Passen Sie expressions an die emotionale Lage der Szene an.
3. Wechseln Sie backgrounds, wenn ein neuer Ort betreten wird.
4. Nutzen Sie atmosphere und lighting, um die Stimmung zu verstaerken.
5. Zeigen Sie nur sichtbare Figuren, die wirklich in der Szene anwesend sind.
6. Fuegen Sie missionsrelevante assets mit kontextbezogenen Namen ein.
7. Setzen Sie mission_status nur dann auf "complete", wenn die Mission wirklich abgeschlossen ist.
