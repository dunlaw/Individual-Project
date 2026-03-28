---
name: night-cycle
description: Deutsche Regeln fuer den Nachtzyklus mit Rueckblick, Teacher Chans Predigt und Konzerttexten.
purpose_triggers:
  - night_cycle
---

# Nachtzyklus-Generierung

## Ueberblick

Der Nachtzyklus folgt auf jede Mission und dient als Uebergangsphase mit:
1. Rueckblick auf die Mission
2. Gehirnwaesche durch Teacher Chan
3. Konzert mit toxisch-positiven Texten
4. Vorbereitung auf das naechste Gebetsritual

## JSON-Ausgabestruktur

```json
{
  "reflection_text": "<50-100 Woerter Rueckblick>",
  "teacher_chan_text": "<100 Woerter Gehirnwaesche>",
  "song_title": "<Kreativer Songtitel>",
  "concert_lyrics": [
    "<Zeile 1: 10-15 Woerter>",
    "<Zeile 2: 10-15 Woerter>",
    "<Zeile 3: 10-15 Woerter>",
    "<Zeile 4: 10-15 Woerter>",
    "<Zeile 5: 10-15 Woerter>",
    "<Zeile 6: 10-15 Woerter>",
    "<Zeile 7: 10-15 Woerter>",
    "<Zeile 8: 10-15 Woerter>"
  ],
  "honeymoon_text": "<50 Woerter falscher Frieden>",
  "prayer_prompt": "<Aufforderung fuer das naechste Gebet>"
}
```

## Inhaltsrichtlinien

### reflection_text
- fasst das Geschehene knapp zusammen
- kommentiert den angeblichen "Erfolg" ironisch
- deutet den verdeckten Schaden an

### teacher_chan_text
- deutet das Desaster als spirituellen Sieg um
- nutzt kultartige Sprache
- ignoriert objektive Realitaet
- laesst alle sich gut fuehlen, waehrend alles schlimmer wird

### concert_lyrics
- 8 bis 12 Zeilen
- jede Zeile 10 bis 15 Woerter
- Stil: toxische Positivitaet, Kultpropaganda, Realitaetsverweigerung
- die Texte sollen leer, widerspruechlich und pseudoheilsam wirken

### honeymoon_text
- beschreibt die unheimliche Ruhe nach der Mission
- Teammitglieder wirken auffaellig freundlich
- deutet an, dass dieser Frieden nicht haelt

### prayer_prompt
- leitet das naechste Gebetsritual ein
- soll leicht unheilvoll wirken

## Ausgaberegeln

- Es darf nur gueltiges JSON ausgegeben werden.
- Keine Prosa ausserhalb des JSON.
- concert_lyrics muss ein Array von Strings sein.
- Alle Felder sind Pflichtfelder.
