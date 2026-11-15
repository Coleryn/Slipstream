---
name: dodge-ui-style
description: Enforces a strict minimalist geometric art style (inspired by Coolmath's "Dodge") and game-feel feedback for the Godot endless runner "Slipstream". Use this skill whenever creating or changing ANY visual element - UI, HUD, menus, buttons, game over screen, player, squares, particles, backgrounds, colors, fonts, animations, screen shake, or sound feedback - even if the user doesn't mention style. Also use it when the user says things like "make it look better", "add a menu", "polish", or "add effects". Prevents generic AI-looking UI (default Godot theme, gradients, rounded cards, drop shadows, emoji icons, neon glow).
---

# Dodge UI Style

This project must look like a tiny, clean, hand-tuned arcade game, **not** like a generic AI-generated app. Every visual decision follows the rules below. If a rule conflicts with a default habit, the rule wins.

## Reference

The visual reference is the browser game **Dodge** on Coolmath Games (https://www.coolmathgames.com/0-dodge): one lone circle, many squares, flat shapes on a calm dark-blue field, and a satisfying "enemies collide with each other" payoff.

If a screenshot exists in `reference/` (for example `reference/dodge.png`), look at it before designing anything visual and match it. Do not invent a new style.

## Core look: the 7 rules

1. **Shapes only.** Everything is a circle, square, or rectangle drawn with `_draw()`, `ColorRect`, or `Polygon2D`. No sprites, no icons, no emoji, no imported images.
2. **Flat color.** Solid fills only. No gradients, no textures, no inner shadows, no drop shadows, no glow or bloom, no outlines unless a shape needs to read against the background. Flat **two-tone** is allowed: one smaller inner shape of the same hue at a fixed darker shade (see Two-tone shapes).
3. **Tiny palette.** Use only the colors in the palette table below. Define them once in a single `Palette` script (autoload or `class_name`) and never hardcode a color anywhere else.
4. **Sharp over soft.** Squares have sharp corners (no rounded corners). UI rectangles also have sharp corners. The only round thing in the game is the player circle and the pulse ring.
5. **Lots of empty space.** The play field is mostly empty. Keep the HUD tiny and at the edges. Nothing should compete with the player and the squares.
6. **One typeface, few sizes.** One clean sans-serif font (bundle a single free font such as Nunito, Quicksand or Poppins) in at most 3 sizes: large (score on game over), medium (buttons, HUD), small (labels). No bold-plus-italic-plus-shadow combinations.
7. **Motion is the decoration.** Instead of ornamental graphics, use motion: scale pops, quick fades, small shakes. Everything that appears should animate in; nothing should just blink into existence.

## Two-tone shapes (allowed)

Flat two-tone is the only permitted decoration on a shape. It is a second flat fill, never an effect:

- At most **one** smaller centered inner shape per form, same hue, darker with a fixed factor from `Palette` (`Palette.INNER_DARKEN_FACTOR`, default `0.82`).
- Inner size about **55%** of the outer (`square_inner_ratio` / `player_inner_ratio` in `FeedbackConfig`).
- Applies to gameplay squares (grey, red, gold, big) and to the player circle (white disc with a very light grey-blue inner disc, `Palette.PLAYER_INNER`).
- Sharp corners, no outlines, no highlights, no shadows - if it looks soft, it is wrong.
- Trail copies keep the player colours and only fade and shrink.

## Background parallax (allowed, optional)

The field may carry **6-8 very large flat squares** drifting slowly downward behind the game, parallax style.

- Colours are derived from `Palette.BACKGROUND` and must stay within **6%** of it (use `Palette.lift` / `Palette.shade`).
- They must never compete with gameplay: no outlines, no interaction, no motion blur, no glow.
- Export an on/off toggle (`Backdrop.enabled`) and keep the count and speeds exported so they can be tuned or disabled.

## Palette (single source of truth)

| Role | Color | Notes |
|---|---|---|
| Background | `#2A445D` | Muted dark blue taken from the reference game's theme color. Slightly darker variant `#1F3347` is allowed for UI panels. |
| Player | `#FFFFFF` | Pure white circle. |
| Normal squares | `#8FA3B5` | Cool grey-blue. Calm, low threat. |
| Fast squares | `#E85D5D` | Soft red. Signals danger. |
| Gold squares | `#F2C94C` | Rare bonus only. |
| Text and HUD | `#FFFFFF` at 70-100% opacity | Never any other text color. |
| Crash particles | Same color as the square that broke | Small squares, never circles. |
| Player inner disc | `#DBE4EC` | Very light grey-blue, `Palette.PLAYER_INNER`, inner 55%. |
| Background parallax | `Palette.BACKGROUND` within 6% | Use `Palette.lift` / `Palette.shade`, never more than 6%. |

Do not add colors. If a new element seems to need one, reuse a palette color at a different opacity.

## UI rules (the part AI usually gets wrong)

### Never do this
- Do not use the default Godot theme or default grey buttons. Always override the theme.
- Do not make rounded "card" panels, glassmorphism, or frosted blur.
- Do not add gradients, neon outlines, glow, or purple-to-blue color schemes.
- Do not use emoji or icon fonts for buttons (no play triangle emoji, no gear emoji).
- Do not add drop shadows to text or panels.
- Do not add long menus, settings screens, tutorials, or splash logos unless the user asks.
- Do not center everything in a stack of big boxed sections.
- Do not add decorative borders, dividers, or ornamental backgrounds.
- Do not write marketing-style text ("Embark on your journey!"). Use short, plain words.

### Always do this
- **Buttons** are flat rectangles with sharp corners, one solid fill (white or palette color), dark text on light fill. Hover or press feedback is a quick scale (about 1.0 to 1.05) or color change, never a shadow.
- **HUD** is minimal: score top-center in medium size, combo multiplier below it in small size (shown only when above x1), high score small in a top corner. Nothing else on screen during play.
- **Game over screen** is almost empty: the word "Game Over" or just the score in large type, best score in small type, and one Restart button. A fast fade/scale-in. Restarting must take one tap.
- **Main menu** (only if requested): the title text, one Play button, and maybe a few drifting squares in the background. Nothing else.
- **Text** is short, lowercase or Title Case, no exclamation-mark spam.
- Layout uses generous margins and a consistent grid (multiples of 8 px).

## Game-feel feedback (always follow)

The reference game feels good because every action gives immediate, readable feedback. Every gameplay event must have feedback built from shapes, motion, and sound.

| Event | Required feedback |
|---|---|
| Player moves | Smooth lerped follow, subtle fading trail of circle copies (low opacity). |
| Square meets square (crash) | Both squares burst into small rotated square particles in their own colors, one thin hollow shockwave square each (about 2.5x, under 0.3 s), brief slow-motion (about 0.2-0.3 s), light screen shake, score popup that floats up and fades. |
| Red square spawn | A 2 px flat lane line at the top edge, 40% opacity, about 0.4 s before the red square enters, fading as it appears. |
| Combo increases | Multiplier text pops (quick scale up then settle), pitch of crash sound rises with combo. |
| Near miss | Tiny subtle pulse or flash on the player (white to slightly larger and back). Optional small bonus. |
| Player dies | Player circle shrinks or bursts, short freeze frame (about 0.1 s), stronger shake, then the game over UI fades in. |
| Gold pickup / shield | Expanding thin ring around the player (the only ring allowed besides pulse). |
| Pulse ability | Expanding circle ring plus nearby squares pushed with a small shake. |
| UI buttons | Scale pop on press, soft click sound. |

Feedback rules:
- Effects are **short** (under about 0.4 s) and **subtle**. Never full-screen flashes or long particle storms.
- Screen shake is small and decays quickly. Respect a `shake_enabled` flag for accessibility.
- Keep all timings, shake strengths, and slow-motion values in one `FeedbackConfig` script as exported variables so they can be tuned.
- Sound is minimal: soft clicks, a pop on crash, a low thud on death. Background music is allowed as one quiet, calm loop (see AGENTS.md, "Audio and music"); no music overload. Placeholder hooks are fine.

## Implementation checklist for any visual task

Before finishing, verify each item:

- [ ] Only palette colors are used, and they come from the `Palette` script
- [ ] No images, icons, emoji, gradients, shadows, or glow were added
- [ ] Corners are sharp (except the player circle and rings)
- [ ] The default Godot theme is not visible anywhere
- [ ] The screen still has plenty of empty space
- [ ] Every new element animates in or out
- [ ] Every new gameplay event has feedback from the table above
- [ ] Tunable values are exported variables or in `FeedbackConfig`
- [ ] The layout works at 540x960 portrait and on touch (buttons at least 64 px tall)

## When unsure

If a request is ambiguous about style, choose the **simpler, flatter, emptier** option. If the user asks for something that breaks these rules (for example "add a glowing gradient button"), do it only if they explicitly confirm they want to leave the Dodge style, and say which rule it breaks.
