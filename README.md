![CricStatz Logo](app/assets/icons/logo.png)

CricStatz is an open-source Flutter app to record and track cricket matches played in grounds, local leagues, and practice sessions.

The goal is simple: make scorekeeping fun, reliable, and shareable so everyone can see match and player stats.

## Vision
- Create teams and players
- Configure matches (10 over, 20 over, custom)
- Track live scoring ball by ball
- Show player and team stats over time

## Tech Direction
- Flutter (mobile app)
- Provider (state management)
- Supabase (backend + database)

## Repository Structure
```
CricStatz/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── design_proposal.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── app/
│   ├── lib/
│   ├── android/
│   ├── test/
│   └── pubspec.yaml
├── design/
│   ├── assets/
│   ├── screens/
│   ├── README.md
│   └── color-palette.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DATABASE_SCHEMA.md
│   └── SETUP.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── SECURITY.md
└── README.md
```

## Figma and Design Workflow
- Primary design source: Figma
- Store approved exports in `design/screens/` and `design/assets/`
- Open a Design Proposal issue before large UI changes

Add your Figma links in `design/README.md`.
## Figma
- Main file link: `https://www.figma.com/design/BeeHZXJXOwpc3qIHxFiQUJ/CRICSTATZ?node-id=139-4519&m=dev&t=3gxyNna0RgE3Pdtq-1`
- Prototype link: `https://www.figma.com/proto/BeeHZXJXOwpc3qIHxFiQUJ/CRICSTATZ?node-id=139-4519&t=3gxyNna0RgE3Pdtq-1`

## Quick Start
1. Install Flutter: `https://docs.flutter.dev/get-started/install`
2. Clone repository:
```bash
git clone https://github.com/<your-username>/CricStatz.git
cd CricStatz
```
3. Enter app folder and install dependencies:
```bash
cd app
flutter pub get
```
4. Verify Flutter setup:
```bash
flutter doctor
```
5. Run app:
```bash
flutter run
```

## Figma MCP Workflow (Codex + Figma)
- Ensure Figma MCP server is installed and connected in your Codex/agent environment.
- In Figma, right-click a frame and choose `Copy link to selection`.
- Ask the agent with a prompt like: `help me implement this Figma design in Flutter using existing components where possible`.
- The agent should call design-context tools to extract layout/style/component details before generating code.
- Iterate code and design both ways, then update exports in `design/screens/` and `design/assets/`.


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


## Contribution Rules
- Read `CONTRIBUTING.md` before opening a PR
- Use issue templates for bug, feature, and design proposals
- Keep PRs focused and reviewable
- Never commit secrets or production keys

## Community Standards
- Code of conduct: `CODE_OF_CONDUCT.md`
- Security reporting: `SECURITY.md`

## License
This project is licensed under GNU GPL v3. See `LICENSE`.

