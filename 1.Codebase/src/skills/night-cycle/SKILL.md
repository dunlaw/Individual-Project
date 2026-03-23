---
name: night-cycle
description: Rules for generating night cycle content including reflection, Teacher Chan's sermon, and concert lyrics.
purpose_triggers:
  - night_cycle
---

# Night Cycle Generation

## Overview

The night cycle occurs after each mission ends. It's a transition period featuring:
1. Reflection on what happened
2. Teacher Chan's brainwashing sermon
3. A concert with toxic positivity lyrics
4. Setup for the next prayer ritual

---

## JSON Output Structure

```json
{
  "reflection_text": "<50-100 words reflecting on the mission>",
  "teacher_chan_text": "<100 words of brainwashing sermon>",
  "song_title": "<Creative song title>",
  "concert_lyrics": [
    "<Line 1: 10-15 words>",
    "<Line 2: 10-15 words>",
    "<Line 3: 10-15 words>",
    "<Line 4: 10-15 words>",
    "<Line 5: 10-15 words>",
    "<Line 6: 10-15 words>",
    "<Line 7: 10-15 words>",
    "<Line 8: 10-15 words>"
  ],
  "honeymoon_text": "<50 words describing false peace>",
  "prayer_prompt": "<Prompt for next prayer ritual>"
}
```

---

## Content Guidelines

### Reflection Text (50-100 words)
- Brief summary of what just happened
- Ironic commentary on the "success"
- Hints at the hidden damage done
- Tone: Darkly reflective

### Teacher Chan's Sermon (100 words)
- Reframes disaster as spiritual victory
- Uses cult-like religious language
- Completely ignores objective reality
- Makes everyone feel good about feeling bad

### Concert Lyrics (8-12 lines)
- Each line: 10-15 words
- Style: Toxic positivity / cult worship
- Themes: Forced happiness, denial of reality, submission
- Should feel like propaganda set to music

**Core Characteristics of the Lyrics (MANDATORY):**

1. **Empty Signifiers (空洞的符號)**
   - Use warm, inspirational-sounding words that lack concrete meaning
   - Repeat vague concepts like "shine," "light," "glow," "flow," "rise," "bloom"
   - Create the illusion of profundity through meaningless rhetoric
   - Beautiful-sounding nonsense with zero substantive content

2. **Severe Logical Inconsistency & Self-Contradiction**
   - Forcefully stitch together opposing concepts
   - Examples: "embrace pain as joy," "failure is success," "darkness is light"
   - Display "people-pleasing personality" traits
   - Contradict within the same line: "be yourself" yet "just be ordinary"

3. **False Encouragement with Hidden Conditions**
   - Surface appearance of unconditional support
   - Subtly shifts responsibility away from the individual
   - Encourages passive waiting for luck rather than active improvement
   - Attributes success to external conditions, not personal effort
   - Uses conditional phrases disguised as encouragement

4. **Extreme Subjective Determinism & Self-Deception**
   - Defines success/failure purely by subjective feelings
   - Ignores objective standards completely
   - "If you feel successful, you are successful"
   - Essentially escaping reality through emotional manipulation
   - Makes the concept of "success" meaningless

5. **Sophisticated Ambiguity as Psychological Anesthesia**
   - Uses deliberate vagueness as a mirror for projection
   - Not proclaiming truth, but offering emotional comfort
   - Prioritizes "healing" over "truth-seeking"
   - Sacrifices basic logic for therapeutic effect
   - Functions as "spiritual chicken soup" or "psychological anesthetic"
   - Comparable to oversimplified children's propaganda songs

### Honeymoon Text (50 words)
- Describes the eerie calm after the mission
- Teammates acting suspiciously nice
- Foreshadows that this peace won't last

### Prayer Prompt
- Guides player to write their next prayer
- Should be vaguely ominous
- Examples:
  - "What do you wish for the next mission?"
  - "Speak your heart's desire to the cosmos..."

---

## English Example

```json
{
  "reflection_text": "The mission was declared a 'success.' The village is 'saved.' Yet somehow, the survivors' eyes are emptier than before. The Positive Energy readings are off the charts. Everyone is smiling. No one is happy.",
  "teacher_chan_text": "Beloved children of light! Today we witnessed a MIRACLE! What some might call 'collateral damage' was actually the universe pruning the weak branches! Every tear shed was a seed of future joy! Let us CELEBRATE our inevitable victory over negativity!",
  "song_title": "Shine Through Everything",
  "concert_lyrics": [
    "You're already perfect just by being ordinary, shine your unique light!",
    "When you feel like you've won, you've won, that's all that matters!",
    "Embrace your failures as success, pain is just joy waiting to bloom!",
    "Don't think too hard, just glow, the universe will handle the rest!",
    "You're the main character, yet humbly blend into the background!",
    "Rise above by staying grounded, be yourself by being everyone!",
    "Your tears are diamonds, your doubts are certainty in disguise!",
    "Trust the flow, surrender your will, freedom comes from letting go!",
    "Shine, glow, rise, bloom - these words mean everything and nothing!",
    "If it feels right, it is right, objective truth is optional!"
  ],
  "honeymoon_text": "An strange calm settles over the agency. Gloria offers you tea without a single passive-aggressive comment. Donkey actually listens when spoken to. It feels wrong. Like the world holding its breath.",
  "prayer_prompt": "Close your eyes and whisper your hopes for tomorrow..."
}
```

## Chinese Example (中文範例)

```json
{
  "reflection_text": "任務被宣告為「成功」。村莊「獲救」了。然而倖存者的眼神卻比以前更空洞。正能量讀數爆表。每個人都在微笑。沒有人快樂。",
  "teacher_chan_text": "光明的孩子們！今天我們見證了奇蹟！有些人稱之為「附帶損害」，實際上是宇宙在修剪弱枝！每一滴眼淚都是未來喜悅的種子！讓我們慶祝戰勝消極的必然勝利！",
  "song_title": "在一切中發光",
  "concert_lyrics": [
    "你只要平凡就已經完美，綻放你獨特的光芒吧！",
    "當你覺得自己贏了，你就贏了，這才是重點！",
    "擁抱失敗就是成功，痛苦只是等待綻放的喜悅！",
    "別想太多，只管發光，宇宙會處理剩下的事！",
    "你是主角，卻要謙卑地融入背景之中！",
    "通過紮根來超越，通過成為所有人來做自己！",
    "你的眼淚是鑽石，你的懷疑是偽裝的確定性！",
    "相信流動，放棄意志，自由來自放手！",
    "發光、閃耀、上升、綻放——這些詞既是一切又什麼都不是！",
    "如果感覺對了就是對的，客觀真理是可選的！"
  ],
  "honeymoon_text": "一種詭異的平靜籠罩著機構。Gloria給你倒茶時沒有一句被動攻擊的評論。Donkey真的在聽你說話。這感覺不對勁。就像世界在屏住呼吸。",
  "prayer_prompt": "閉上眼睛，向明天低語你的希望..."
}
```

---

## Output Requirements

- **MUST be valid JSON only**
- No prose or explanation outside the JSON
- concert_lyrics MUST be an Array of Strings
- All fields are required
