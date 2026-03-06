# Design Workspace

CricStatz design source lives in Figma, with exported assets tracked in this folder.

## Figma
- Main file link: `https://www.figma.com/design/BeeHZXJXOwpc3qIHxFiQUJ/CRICSTATZ?node-id=139-4519&m=dev&t=3gxyNna0RgE3Pdtq-1`
- Prototype link: `https://www.figma.com/proto/BeeHZXJXOwpc3qIHxFiQUJ/CRICSTATZ?node-id=139-4519&t=3gxyNna0RgE3Pdtq-1`

## Contribution Flow For Designers
1. Create or update designs in Figma.
2. Open a `Design proposal` issue with frame links.
3. After approval, export final assets.
4. Add exports in this directory and open a PR.

## Folder Rules
- `design/screens/`: screen exports by flow
- `design/assets/`: reusable icons, illustrations, logos
- Keep filenames descriptive and lowercase with hyphens

## Naming Examples
- `match-setup-step-1.png`
- `score-entry-bottom-sheet.png`
- `team-logo-default.svg`

---

## Website

### Website Redesign

The CricStatz landing page (`website/`) was completely redesigned as a modern single-page app built with plain HTML/CSS/JS.

- **Layout**: 5 full-viewport scroll-snap sections — Hero, About, Features, Download, Footer
- **Theme**: Dark/red palette derived from `logo.png` (`#000000` base, `#ae1921` / `#e11d48` accents)
- **Logo**: Prominently displayed in the hero with a red glow and floating animation
- **Navigation**: Fixed navbar with active link tracking via `IntersectionObserver`
- **Scroll Reveals**: Fade-up, scale-in, and staggered card animations triggered on scroll
- **Code Structure**: Styles extracted to `styles.css`, interactivity in `script.js`

### Animation

A custom cricket-themed animation plays when the user clicks the **Download APK** button:

1. A dark backdrop fades in
2. The batsman (`appicon.png`) slides in from the left with a swing motion
3. A cricket ball (with seam detail) launches from the bat and flies toward the user, scaling up rapidly
4. On "impact" — a red radial flash and an expanding ring fill the screen
5. The overlay clears and the APK download begins

### Phases

| Phase | Status | Summary |
|-------|--------|---------|
| **Phase 1** | ✅ Completed | Full website redesign — 5-section scroll-snap layout, dark/red theme, scroll-reveal animations, initial download button animation |
| **Phase 2** | 🔄 In Progress | Improved download animation with `appicon.png` bat-swing motion, realistic ball-fly-to-user effect, impact flash (no shake). Added **Team Chats** feature card |
