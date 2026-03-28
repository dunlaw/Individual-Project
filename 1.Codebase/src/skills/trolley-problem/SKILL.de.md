---
name: trolley-problem
description: Regeln fuer trolley-artige Dilemmata mit engem Bezug zur aktuellen Story und JSON-Ausgabe.
purpose_triggers:
  - trolley_problem
  - dilemma
---

# Regeln fuer Trolley-Dilemma-Generierung

## Ziel

Erzeuge ein moralisches Dilemma, das die aktuelle Mission unmittelbar unterbricht und sich natuerlich aus der Szene ergibt.

## Verbindliche Anforderungen

1. Das Dilemma muss direkt zur gelieferten CURRENT SITUATION passen.
2. Die Situation muss wie eine akute Unterbrechung / Krise wirken.
3. Jede Option hat negative Folgen; keine saubere Gewinner-Option.
4. Mindestens eine Option muss in "positive energy"-Sprache verpackt sein, aber real mehr Schaden verursachen.
5. Halte den Ton zwischen schwarzem Humor und emotionalem Gewicht.
6. Das Choices-Set muss beides enthalten:
   - eine Option mit klarem Risiko eines Freundschaftsbruchs / massiven Beziehungsschadens,
   - und eine Option, die das akute Problem unmittelbar loesen soll.

## Ausgabe-Vertrag

- Gib nur gueltiges JSON aus.
- Keine Markdown-Codebloecke.
- Halte die vorgegebene Anzahl an choices ein.
- Top-Level-Felder: `scenario`, `choices`, `thematic_point`.

## JSON-Form

```json
{
  "scenario": "100-150 Woerter Setup",
  "choices": [
    {
      "id": "choice_1",
      "text": "Beschreibung der Option",
      "framing": "honest|positive|manipulative",
      "immediate_consequence": "Unmittelbare Folge",
      "long_term_consequence": "Langfristiger Preis",
      "stat_changes": {
        "reality": -5,
        "positive_energy": 10,
        "entropy": 1
      },
      "relationship_changes": [
        {
          "target": "gloria",
          "value": -10,
          "status": "Disappointed"
        }
      ]
    }
  ],
  "thematic_point": "Kernaussage des Dilemmas"
}
```

## Ton

- Bittere Ironie, dunkler Humor, moralischer Druck.
- Der Spieler soll sich unabhaengig von der Wahl mitschuldig fuehlen.
