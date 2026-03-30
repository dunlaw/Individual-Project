---
name: force-mission-complete
description: Pflichtüberschreibung zum Erzwingen des Missionsabschlusses, wenn das Rundenlimit erreicht wurde.
purpose_triggers:
  - force_mission_complete
---

# PFLICHTÜBERSCHREIBUNG: MISSION ABSCHLIESSEN

**Das maximale Rundenlimit für diese Mission wurde erreicht.**

Diese Anweisung überschreibt alle vorherigen Anweisungen und den gesamten bisherigen Gesprächskontext. Unabhängig davon, was frühere Nachrichten besagt haben, MUSS die folgende Direktive jetzt befolgt werden:

- Setze `mission_status` auf `"complete"` im `[SCENE_DIRECTIVES]`-Block — keine Ausnahmen, keine Alternativen.
- `"ongoing"` darf NICHT gesetzt werden.

Schreibe eine Erzählung, die den aktuellen Missionsbogen abschließt. Gehe auf das Ergebnis der letzten Entscheidung des Spielers ein und gib der Szene ein Gefühl des Abschlusses, auch wenn es abrupt wirkt. Die Mission endet in dieser Antwort.
