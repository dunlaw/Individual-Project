---
name: entropy-effects
description: Narrative Richtlinien fuer verschiedene Entropiestufen und deren Einfluss auf den Ton der Erzaehlung.
purpose_triggers:
  - entropy_high
  - entropy_medium
---

# Entropieeffekte auf die Erzaehlung

## Ueberblick

Void Entropy misst, wie stark die Welt durch erzwungenen Optimismus zerfallen ist. Hoehere Entropie bedeutet absurdere und chaotischere Erzaehlungen.

## Entropiestufe: KRITISCH (>= 0.7)

Wenn die Entropie kritische Werte erreicht, gelten diese PFLICHTANWEISUNGEN:

```
[ENTROPY: CRITICAL - Level {value}]
Die Welt versinkt in Chaos und Absurditaet. Die Void Entropy hat den kritischen Bereich erreicht.

MANDATORY NARRATIVE DIRECTIVES:
- Erzeugen Sie surreale, schwarzhumorige und tief ironische Ereignisse.
- Unterlaufen Sie juengste positive Handlungen des Spielers mit verdrehten Konsequenzen.
- Nutzen Sie absurde Logik und unsinnige Ursache-Wirkungs-Ketten.
- Die Realitaet selbst soll instabil und traumartig wirken.
- Verspotten Sie Optimismus mit grotesker Uebertreibung.
- Erzeugen Sie Situationen, in denen Erfolg und Scheitern ununterscheidbar werden.

Je hoeher die Positive Energy, desto staerker zerbricht die Wirklichkeit. Das ist der Fluch des erzwungenen Optimismus.
```

## Entropiestufe: ERHOEHT (0.4 - 0.69)

Wenn die Entropie erhoeht, aber noch nicht kritisch ist:

```
[ENTROPY: ELEVATED - Level {value}]
Die Welt wirkt leicht unwirklich. Die Grenze zwischen normal und absurd verschwimmt.

NARRATIVE GUIDANCE:
- Fuehren Sie merkwuerdige oder unerwartete Elemente in sonst normale Situationen ein.
- Geben Sie vertrauten Dingen eine subtile Falschheit.
- Schichten Sie ironische Wendungen in positive Ergebnisse ein.
- Lassen Sie optimistische Handlungen seltsame Nebenwirkungen haben.
- Die Realitaet soll falsch wirken, aber noch nicht vollstaendig chaotisch sein.

Die Void Entropy steigt. Konsequenzen werden unberechenbarer.
```

## Entropiestufe: NIEDRIG (< 0.4)

Keine besonderen Erzaehlmodifikatoren noetig. Behalten Sie den grundlegenden schwarzen Humor und die Ironie bei.

## Implementierungshinweise

- Entropie wird berechnet als `positive_energy / 100.0` zusammen mit weiteren Faktoren.
- Der Schwellwert entscheidet, welche Stufe aktiv ist.
- Diese Richtlinien sollen nur bei mittlerer oder hoher Entropie in den KI-Kontext injiziert werden.
- Bei niedriger Entropie sollte dieses Skill nicht geladen werden, um Tokens zu sparen.
