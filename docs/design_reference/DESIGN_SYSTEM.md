---
name: Serene Safety
colors:
  surface: '#fbf8fb'
  surface-dim: '#dbd9dc'
  surface-bright: '#fbf8fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f6'
  surface-container: '#efedf0'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e4e2e5'
  on-surface: '#1b1b1e'
  on-surface-variant: '#44474d'
  inverse-surface: '#303033'
  inverse-on-surface: '#f2f0f3'
  outline: '#75777e'
  outline-variant: '#c5c6ce'
  surface-tint: '#4f5e7e'
  primary: '#041632'
  on-primary: '#ffffff'
  primary-container: '#1b2b48'
  on-primary-container: '#8393b5'
  inverse-primary: '#b7c7eb'
  secondary: '#006d37'
  on-secondary: '#ffffff'
  secondary-container: '#6bfe9c'
  on-secondary-container: '#00743a'
  tertiary: '#241300'
  on-tertiary: '#ffffff'
  tertiary-container: '#402500'
  on-tertiary-container: '#cd8100'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d7e2ff'
  primary-fixed-dim: '#b7c7eb'
  on-primary-fixed: '#091b37'
  on-primary-fixed-variant: '#374765'
  secondary-fixed: '#6bfe9c'
  secondary-fixed-dim: '#4ae183'
  on-secondary-fixed: '#00210c'
  on-secondary-fixed-variant: '#005228'
  tertiary-fixed: '#ffddb9'
  tertiary-fixed-dim: '#ffb961'
  on-tertiary-fixed: '#2b1700'
  on-tertiary-fixed-variant: '#663e00'
  background: '#fbf8fb'
  on-background: '#1b1b1e'
  surface-variant: '#e4e2e5'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Manrope
    fontSize: 26px
    fontWeight: '800'
    lineHeight: 32px
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
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
  sm: 16px
  md: 24px
  lg: 32px
  xl: 48px
  edge-margin: 20px
  gutter: 12px
---

## Brand & Style
The design system is centered on the concept of "Silent Guardian." It avoids the chaotic, high-stress aesthetics typical of emergency software, opting instead for a **Corporate / Modern** aesthetic that emphasizes stability and professional care. 

The target audience consists of vehicle owners and fleet managers in the Peru/LATAM market who value proactive security. The UI evokes a sense of being "always watched over" without being intrusive. 

Key visual principles:
- **Atmospheric Clarity:** Using generous white space to allow critical information to breathe.
- **Soft Precision:** High-tech utility balanced with human-centric softness through rounded forms.
- **Trust-First Architecture:** Using a muted navy primary to anchor the experience in reliability, reserving vibrant colors strictly for status communication.

## Colors
This design system utilizes a semantic-heavy palette to ensure immediate comprehension of vehicle and safety status.

- **Primary (Muted Navy):** #1B2B48. Used for global navigation, headers, and primary actions. It conveys authority and technical sophistication.
- **Success (Emerald Green):** #2ECC71. Represents "URBES Operativo." Used for active connection states and "all-clear" summaries.
- **Warning (Soft Amber):** #F39C12. Used for "Posible Accidente" or "Revisión Requerida." It draws attention without triggering panic.
- **Critical (Coral Red):** #E74C3C. Strictly reserved for "ALERTA DE ACCIDENTE." High-visibility but balanced with white surfaces to maintain legibility.
- **Neutrals:** The background uses a very light cool gray (#F8F9FA) to differentiate from the pure white (#FFFFFF) elevation of interaction cards.

## Typography
**Manrope** is selected for its modern, geometric construction and exceptional legibility at small sizes. The typeface feels technical yet approachable, fitting the "smart mobility" narrative.

- **Hierarchy:** Use `display-lg` for critical alerts only. `headline-md` should be used for card titles.
- **Language Nuance:** Spanish text tends to be 15-20% longer than English; line heights are set generously to prevent text crowding in multi-line descriptions or localized Peru-specific addresses.
- **Status Labels:** Always use `label-sm` in ALL CAPS with 0.05em tracking for secondary data points like "DISPOSITIVO CONECTADO" or "GPS ACTIVO."

## Layout & Spacing
The layout follows a **Fluid Grid** model optimized for one-handed mobile use. 

- **Safe Zones:** A 20px edge margin is maintained globally to ensure content does not hug the screen edges, reinforcing the premium, "breathable" feel.
- **Card Spacing:** Use `md` (24px) vertical spacing between major dashboard cards to create clear visual separation of distinct data sets (e.g., Map vs. Status).
- **Internal Padding:** Cards should use a consistent `sm` (16px) or `md` (24px) internal padding depending on the density of the information.
- **Mobile-First Reflow:** Elements are primarily stacked vertically. On larger mobile screens (Max width), content containers should cap at 600px and center to maintain readability.

## Elevation & Depth
The design system uses **Tonal Layers** combined with **Ambient Shadows** to create a structured hierarchy.

- **Base Layer:** The background surface (#F8F9FA) is flat.
- **Interaction Layer:** White cards (#FFFFFF) sit on the base layer. They use a very soft, diffused shadow: `0px 4px 20px rgba(27, 43, 72, 0.08)`. The shadow color is tinted with the Primary Navy to ensure a natural, integrated appearance.
- **Active Alert Layer:** For "ALERTA DE ACCIDENTE," the card may use a subtle colored glow or a high-contrast border to bypass the standard elevation hierarchy.
- **Overlays:** Modals and bottom sheets use a 40% opacity navy backdrop blur to keep the user focused on the immediate task.

## Shapes
The shape language is **Rounded**, reflecting the modern automotive interiors of connected vehicles.

- **Primary Cards:** Use `rounded-xl` (1.5rem/24px) for the main container cards to evoke a friendly, safe, and premium feel.
- **Buttons and Inputs:** Use `rounded-lg` (1rem/16px) for a consistent tactile experience.
- **Status Pills:** Use fully pill-shaped (3rem/48px) containers for status chips like "Operativo" or "En Movimiento."
- **Icons:** Should follow a rounded-corner style; avoid sharp 90-degree angles in iconography to maintain visual harmony with the UI.

## Components

### Buttons
- **Primary:** Navy background, white text. Large touch target (min 56px height). 
- **Critical Action:** Red/Coral background. Used for "SOLICITAR AYUDA" or "LLAMAR EMERGENCIAS."
- **Ghost:** Navy outline, transparent center. Used for secondary settings.

### Cards
- Standard cards feature a white background, 24px corner radius, and a subtle navy-tinted shadow. 
- **Alert Cards:** Feature a top-border accent color (Amber or Red) to indicate the severity of the alert without overwhelming the text.

### Inputs
- **Text Fields:** Light gray border that turns Primary Navy on focus. Labels sit above the field in `label-sm`.
- **Selection:** Large, card-style radio buttons for "Reportar Incidente," making them easy to tap during high-stress moments.

### Chips/Badges
- Small, rounded pills with a background color at 15% opacity of the semantic color (e.g., light green background with dark green text for "Operativo").

### Progress Indicators
- For "Sending Alert" states, use a circular countdown or a linear bar in Primary Navy to indicate system activity. Avoid "spinning" loaders which can increase user anxiety; use steady progress bars instead.