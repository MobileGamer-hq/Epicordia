---
name: Epicordia System
colors:
  surface: '#f9f9fe'
  surface-dim: '#d9d9df'
  surface-bright: '#f9f9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f9'
  surface-container: '#ededf3'
  surface-container-high: '#e8e8ed'
  surface-container-highest: '#e2e2e8'
  on-surface: '#1a1c20'
  on-surface-variant: '#444654'
  inverse-surface: '#2f3035'
  inverse-on-surface: '#f0f0f6'
  outline: '#747686'
  outline-variant: '#c4c5d7'
  surface-tint: '#2b50d8'
  primary: '#0137c3'
  on-primary: '#ffffff'
  primary-container: '#2f53db'
  on-primary-container: '#d6dbff'
  inverse-primary: '#b8c3ff'
  secondary: '#785a00'
  on-secondary: '#ffffff'
  secondary-container: '#ffce5c'
  on-secondary-container: '#755700'
  tertiary: '#00543f'
  on-tertiary: '#ffffff'
  tertiary-container: '#006f54'
  on-tertiary-container: '#89f1ca'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dde1ff'
  primary-fixed-dim: '#b8c3ff'
  on-primary-fixed: '#001355'
  on-primary-fixed-variant: '#0035bd'
  secondary-fixed: '#ffdf9c'
  secondary-fixed-dim: '#f0c04f'
  on-secondary-fixed: '#251a00'
  on-secondary-fixed-variant: '#5b4300'
  tertiary-fixed: '#8ef6d0'
  tertiary-fixed-dim: '#72d9b4'
  on-tertiary-fixed: '#002117'
  on-tertiary-fixed-variant: '#00513d'
  background: '#f9f9fe'
  on-background: '#1a1c20'
  surface-variant: '#e2e2e8'
typography:
  display:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  h1:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  h2:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: '0'
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  display-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style

The design system is anchored in the concept of "Digital Zen"—a calm, professional, and hyper-focused productivity environment. It is designed for deep work, prioritizing clarity over decoration and utility over noise. Drawing inspiration from Milanote’s canvas-based spatial organization and Notion’s systematic cleanliness, the UI feels more like a physical workbench than a digital application.

The design style is **Modern Professional with a Tactile Edge**. It utilizes a "Flat-Plus" approach: primarily flat surfaces defined by precise 1px borders, with subtle elevation used only to denote active states or temporary overlays. The aesthetic is intentional, grounded, and quiet, ensuring the user's content remains the focal point. By removing standard checkboxes in favor of interactive rings and avoiding traditional login friction, the system feels immediate and unencumbered.

## Colors

This design system utilizes a sophisticated, low-fatigue palette. The neutral tones are slightly warm in light mode (`#FAFAF8`) and deep charcoal in dark mode (`#101216`) to reduce eye strain during long sessions. 

- **Primary Blue:** Used for calls to action and active states. In dark mode, the blue shifts to a higher luminance (`#6E96FF`) to maintain accessibility.
- **Canvas vs. Surface:** A distinction is made between the "Canvas" (the infinite background) and "Surfaces" (the interactive containers). Surfaces use a crisp white or deep grey to pop against the slightly darker/lighter canvas backgrounds.
- **Semantic Accents:** A curated set of five pastel-muted colors is used for tagging and pinning, providing visual categorization without breaking the professional atmosphere.

## Typography

The system relies exclusively on **Inter**, a geometric-humanist sans-serif known for its exceptional legibility and systematic feel. 

- **Hierarchy:** We use a tight scale to maintain a professional, information-dense environment. Bold weights are reserved for `Display` and `H1` to create clear entry points for the eye.
- **Utility:** `Body` text is set at 14px to maximize content density without sacrificing readability on high-resolution displays.
- **Letter Spacing:** Headlines utilize negative tracking (-0.01em to -0.02em) to appear tighter and more "designed," while captions use slight positive tracking to ensure clarity at small scales.

## Layout & Spacing

The layout philosophy follows a **Canvas-First** model. Unlike rigid columnar websites, this design system treats the viewport as a workspace where elements can exist in a structured grid or a freeform canvas.

- **Grid:** For structured views (lists, settings), a 12-column fluid grid is used with 16px gutters.
- **Rhythm:** A 4px base unit governs all padding and margin decisions. 
- **Touch Targets:** On mobile, all interactive icons are encased in a 44px circular "hit area" container, regardless of the icon's visual size, to ensure effortless navigation.
- **Safe Areas:** 16px side margins are maintained on mobile, expanding to 40px on desktop to provide visual breathing room.

## Elevation & Depth

This system avoids heavy drop shadows to maintain a clean, professional aesthetic. Depth is communicated through **Tonal Layering** and **Line Work**.

- **Level 0 (Canvas):** The base background layer (`canvas_bg`).
- **Level 1 (Surface):** Cards, notes, and panels sit on this layer with a 1px `border_subtle`.
- **Active/Lifted State:** Only when an element is being dragged or is "active" (like a dropdown) is a shadow applied. The shadow should be a highly diffused, low-opacity neutral (e.g., `0px 10px 20px rgba(0,0,0,0.06)`).
- **Interactive States:** Hovering over a surface should darken/lighten the border to `border_strong` rather than increasing shadow depth.

## Shapes

The shape language is "Soft-Modular." By using a range of corner radii, we distinguish between structural containers and interactive elements.

- **xs (6px):** Small utility items like tooltips or tags.
- **s (10px):** Small cards or input fields.
- **m (16px):** Standard card containers.
- **l (20px):** Large modal overlays or main content areas.
- **pill (999px):** Exclusively for buttons and interactive ring indicators.

## Components

- **Buttons:** 
    - *Primary:* Pill-shaped, solid `primary_color` with white text. 
    - *Secondary:* Pill-shaped, 1px `primary_color` outline, no fill.
    - *Ghost:* Pill-shaped, no border or fill, primary-colored text.
- **The "Ring" (Status Indicator):** In place of checkboxes, use a 20px circular ring. An empty ring (1px `border_strong`) represents "incomplete." A filled ring (primary color with a centered white dot or check) represents "complete." This reinforces the calm, non-mechanical brand.
- **Input Fields:** 1px `border_subtle` with a `radius-s`. On focus, the border transitions to `primary_color` with no outer glow.
- **Cards:** Use `radius-m`, white/surface background, and 1px `border_subtle`.
- **Icon Containers:** For mobile, icons must be centered within a 44px circle. The circle itself remains transparent unless tapped, providing a consistent interaction zone.
- **Chips/Tags:** Use `radius-xs` and the accent palette. Chips should have a light tinted background and a darker version of the same color for text.