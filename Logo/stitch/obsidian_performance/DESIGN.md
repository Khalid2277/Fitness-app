# Design System: High-Performance Refinement

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Intelligent Athlete."** 

Unlike typical fitness applications that rely on aggressive neons and high-intensity "gamified" aesthetics, this system prioritizes the quiet confidence of high-end performance tools. It is an editorial-first interface that treats biometric data with the reverence of a premium Swiss timepiece. 

The "template" look is broken through **Intentional Asymmetry**. Instead of rigid, centered grids, we utilize generous horizontal breathing room and offset typography to lead the eye. We favor "Matte Depth"—a tactile, layered approach that feels like stacked sheets of dark slate—rather than artificial digital glows.

---

## 2. Colors: The Tonal Depth Strategy
Our palette is rooted in deep, midnight blues and sophisticated neutrals. Color is used as a functional tool for information hierarchy, not just decoration.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through background color shifts or tonal transitions.
- Use `surface_container_low` (#181c22) for the base page background.
- Use `surface_container` (#1c2026) for primary content blocks.
- The shift from 181c22 to 1c2026 provides a "soft edge" that is felt rather than seen, maintaining a premium, seamless flow.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Use the `surface_container` tiers to create nested depth:
1.  **Level 0 (Base):** `surface` (#10141a) or `surface_dim`.
2.  **Level 1 (Cards):** `surface_container_low` (#181c22).
3.  **Level 2 (In-Card Elements):** `surface_container_high` (#262a31).

### The "Glass & Matte" Rule
To elevate beyond standard flat design, use Glassmorphism for floating navigation bars or action overlays. 
- **Token:** `surface_variant` (#31353c) at 70% opacity with a `20px` backdrop-blur. 
- This allows the rich deep blues to bleed through, creating a "frosted sapphire" effect that feels expensive and integrated.

### Signature Textures
Avoid heavy gradients. For primary CTAs or high-impact metrics, use a subtle "Atmospheric Gradient":
- **From:** `primary` (#b8c3ff)
- **To:** `on_primary_container` (#5777ff) at a 15-degree angle.
- This provides a "metallic" sheen that implies high-performance gear without looking "cyber."

---

## 3. Typography: The Editorial Voice
We use **Plus Jakarta Sans** as our sole typeface. Its geometric clarity offers a modern, intelligent feel that rivals SF Pro while providing a unique brand signature.

- **Display (display-lg/md):** Used for "hero" metrics (e.g., Heart Rate, VO2 Max). Use `-0.02em` letter spacing to make it feel dense and authoritative.
- **Headline (headline-sm/md):** Used for section titles. Pair a `headline-md` with a `label-md` in `on_tertiary_fixed` for a sophisticated, data-rich header.
- **Title & Body:** `title-md` is for actionable items; `body-md` is for descriptive text.
- **Label (label-sm):** Reserved for micro-data and metadata. Always in `uppercase` with `+0.05em` tracking to ensure legibility on dark backgrounds.

**Hierarchy Strategy:** Focus on "Negative Space as Structure." Increase the spacing between a headline and body text (Scale `4` or `5`) to create an airy, premium feel.

---

## 4. Elevation & Depth
In this system, elevation is conveyed through **Tonal Layering** and **Ambient Light**, never through heavy drop shadows.

### The Layering Principle
Depth is achieved by "stacking." A `surface_container_lowest` (#0a0e14) card placed on a `surface_container` (#1c2026) background creates a "recessed" look, perfect for data input fields or secondary charts.

### Ambient Shadows
When an element must float (e.g., a FAB or a Modal):
- **Shadow Color:** Tinted with `on_background` (#dfe2eb) at 4% opacity.
- **Blur:** Large (32px to 64px).
- **Spread:** -5px to keep the shadow "tucked" under the element, mimicking soft overhead studio lighting.

### The "Ghost Border" Fallback
If contrast is required for accessibility, use a **Ghost Border**:
- **Token:** `outline_variant` (#45474c) at **15% opacity**.
- It should be barely visible, acting as a hint of a container rather than a hard boundary.

---

## 5. Components

### Buttons
- **Primary:** Background: `primary_fixed` (#dde1ff), Text: `on_primary_fixed` (#001356). Radius: `lg` (1rem). No shadow.
- **Secondary:** Background: `secondary_container` (#3f4755), Text: `on_secondary_container` (#adb5c6).
- **Tertiary (Ghost):** No background. Text: `primary`. Used for low-emphasis actions like "View History."

### Input Fields
- **Style:** No bottom line. Use `surface_container_highest` (#31353c) with a `DEFAULT` (0.5rem) corner radius.
- **State:** On focus, transition the background to `surface_bright` (#353940) and add a Ghost Border of `primary` at 20%.

### Cards & Data Lists
- **Rule:** Absolute prohibition of divider lines.
- **Separation:** Use `Spacing Scale 3` (1rem) between list items. Use a background shift (e.g., `surface_container_low`) on hover/active states to define the hit area.

### Performance Chips
- Small, pill-shaped (`full` roundedness) containers using `tertiary_container` (#241707) with `on_tertiary_fixed_variant` text for "High Effort" tags.

---

## 6. Do’s and Don’ts

### Do:
- **Do** use intentional asymmetry. Offset a metric to the left and its label to the right to create a "Dashboard" feel.
- **Do** utilize the full range of `surface_container` tokens to create a sense of architectural "rooms" within the app.
- **Do** keep corner radii consistent (mostly `lg` for cards, `md` for smaller inputs).

### Don’t:
- **Don’t** use pure black (#000000). Always use `surface_container_lowest` (#0a0e14) to maintain depth and prevent "crushed" blacks.
- **Don’t** use neon or vibrant glows. Any "glow" should be an extremely diffused, low-opacity ambient light of `primary` color.
- **Don’t** use 100% opaque borders. They break the "Matte Surface" illusion and make the UI look "cheap" and "boxed-in."