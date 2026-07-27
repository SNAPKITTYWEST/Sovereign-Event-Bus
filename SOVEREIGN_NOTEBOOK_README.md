# SOVEREIGN NOTEBOOK — FRONTEND/UX DESIGN SPECIFICATION

**Complete Interactive Notebook UI for Cryptographically-Sealed Execution**  
**Version**: 1.0 (Complete)  
**Date**: 2026-07-27  
**Status**: DESIGN FINALIZED, READY FOR DEVELOPMENT  
**Author**: Claude Code (Frontend/UX Engineer)

---

## Executive Summary

This directory contains a **complete design specification** for the Sovereign Notebook frontend — an interactive, cryptographically-sealed notebook interface that bridges:

1. **Cell Editing**: Code/Markdown/Math in multiple languages (EmojiCode, Python, Ada, JavaScript, HolyC)
2. **Execution Pipeline**: Isomorphic transformation M1→M2→M3→Runtime→M5→M6 with WORM sealing
3. **Receipt Ledger**: Immutable, Ed25519-signed execution records in a blake3 chain
4. **Dependency Graph**: Visual data flow between cells with hover/click interactions
5. **Animation Engine**: Flowing unicode glyphs, rotating cryptographic seals, receipt chain visualization

**Design Philosophy**: Minimal dependencies (vanilla Web Components), responsive layout, dark mode primary, WCAG 2.1 AA accessibility, 60fps animations.

---

## Three-Document Architecture

### 1. **SOVEREIGN_NOTEBOOK_UI_SPEC.md** (1,800 lines)
**Complete design specification for all UI/UX elements**

- **Layout Architecture**: Desktop 3-column grid, tablet/mobile responsive variants
- **15 Core Components**: Detailed Web Component definitions with state interfaces
- **CSS Architecture**: Design tokens, theme variables, component-level styles
- **Animation Engine**: 5 major animation categories (execution flow, graphs, receipt chain, glyphs, crypto seals)
- **State Management**: Event emitter pattern, reactive subscriptions, persistence
- **Integration Points**: Runtime bridge, WORM ledger, WebLLM execution
- **Keyboard/Mouse/Touch**: Full interaction patterns
- **Accessibility**: WCAG 2.1 AA compliance with ARIA annotations
- **12-Week Roadmap**: 6 phases from foundation to deployment

**Use this when**: Planning overall UI, understanding component architecture, defining styles.

### 2. **SOVEREIGN_NOTEBOOK_FRONTEND_IMPL.md** (1,500 lines)
**Implementation scaffold with runnable code examples**

- **Project Setup**: Package.json, TypeScript config, Vite configuration
- **Type Definitions**: Full TypeScript interfaces for cells, receipts, execution
- **NotebookStore**: Reactive state management with subscriptions
- **Web Components**: Complete examples for NotebookContainer, NotebookCell, CellEditor
- **Animation Engine**: ExecutionFlowAnimator canvas implementation
- **Runtime Bridge**: WebSocket/HTTP client for backend communication
- **CSS Scaffolding**: Design tokens and component styles
- **Entry Point**: index.html and main.ts setup
- **Development Workflow**: Build commands, testing setup

**Use this when**: Starting implementation, copy-pasting component skeletons, setting up build system.

### 3. **SOVEREIGN_NOTEBOOK_ARCH_DIAGRAMS.md** (1,400 lines)
**Visual architecture diagrams and data flow examples**

- **System Architecture**: 3-layer diagram (UI/State/Animation → Bridge → Backend/Runtime/WORM)
- **Execution Pipeline**: 12-step sequence from user click to receipt seal
- **State Management Flow**: Event emitter pattern with subscriber callbacks
- **Component Tree**: Full hierarchy with reactivity subscriptions
- **Animation Orchestration**: Receipt sealing animation sequence (0ms → ∞)
- **Interaction Flows**: Keyboard shortcuts, mouse gestures, touch patterns
- **Responsive Design**: Breakpoints and layout changes at different sizes
- **WORM Chain Verification**: Hash chain integrity algorithm
- **Dependency Resolution**: Topological sort for execution order
- **Canvas Rendering**: 60fps RAF loop with particle updates
- **Error Recovery**: Timeout handling, network errors, dependent cell skipping

**Use this when**: Understanding data flows, debugging state issues, visualizing animations.

---

## Quick Navigation

### For Product Managers
- Read: **UI_SPEC.md § 1 (Layout)** + **§ 2 (Components)** for user-facing features
- Time: 15 minutes
- Output: Understand notebook layout, cell types, receipt viewer

### For Frontend Engineers
- Read: **FRONTEND_IMPL.md** (all sections)
- Then: **UI_SPEC.md § 3-5** for styling and animations
- Then: **ARCH_DIAGRAMS.md** for data flows
- Time: 2-3 hours
- Output: Ready to start Phase 1 development

### For Architects
- Read: **ARCH_DIAGRAMS.md** (all sections)
- Then: **UI_SPEC.md § 4-5** for state patterns
- Then: **FRONTEND_IMPL.md § 6** for integration points
- Time: 1-2 hours
- Output: Understand how frontend integrates with backend isomorphic shift layer

### For QA/Testing
- Read: **UI_SPEC.md § 10 (Testing)** + **§ 9 (Accessibility)**
- Then: **ARCH_DIAGRAMS.md § 11 (Error Recovery)**
- Time: 30 minutes
- Output: Understand test strategies and edge cases

---

## Key Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **Vanilla Web Components** (not React/Vue) | Lightweight, framework-agnostic, WASM-ready | No JSX, manual state binding |
| **Canvas animations** (not DOM) | 60fps particle systems, low overhead | More complex code, requires 2D context expertise |
| **CSS variables for theming** | Dynamic theme switching without JS | Requires CSS Cascade knowledge |
| **Event emitter pattern** | Explicit, debuggable, Prolog-friendly | No async/await, manual unsubscribe |
| **Dark mode primary** | Sovereign aesthetic, reduces eye strain | Light mode needs careful palette |
| **WCAG 2.1 AA from day 1** | Accessibility is not an afterthought | Slightly more verbose component code |
| **TypeScript throughout** | Type safety, IDE support, self-documenting | Build step required, harder debugging |
| **Virtualized cells** | Handle 1000+ cell notebooks efficiently | Complexity in scroll/viewport management |
| **D3 for graphs** | Mature, battle-tested, flexible | Another dependency (but worth it) |
| **Monospace unicode symbols** | Aesthetic + semantic (λ=function, Ω=loop) | Requires Unicode support in all browsers |

---

## Frontend Stack (Minimal)

```json
{
  "Build": "Vite",
  "Language": "TypeScript",
  "UI Framework": "None (Web Components)",
  "Syntax Highlighting": "Highlight.js",
  "Graph Visualization": "D3.js",
  "Math Rendering": "MathJax",
  "Testing": "Vitest",
  "Styling": "CSS 3 (Variables, Grid, Flexbox)",
  "Animation": "Canvas 2D + CSS Keyframes + SVG",
  "State Management": "Custom Event Emitter"
}
```

**Total Bundle Size Target**: < 500KB (before compression)

---

## Component Statistics

| Category | Count | Examples |
|----------|-------|----------|
| **Web Components** | 15+ | NotebookContainer, CellEditor, WormLedger, ExecutionTrace |
| **Animation Classes** | 5 | ExecutionFlowAnimator, DependencyGraphVisualizer, ReceiptChainAnimator |
| **CSS Files** | 8 | global.css, animations.css, layout.css, dark.css, light.css |
| **Type Definitions** | 25+ | Cell, Receipt, ExecutionRequest, CellDependency |
| **Service Classes** | 3 | NotebookStore, RuntimeBridge, ThemeManager |
| **Test Suites** | 12+ | components/, animation/, integration/, e2e/ |

---

## Development Phases (12 weeks)

```
Phase 1: Foundation (Week 1-2)
├─ Web Component base classes
├─ CSS architecture & tokens
├─ Dark/light theme setup
├─ Responsive layout grid

Phase 2: Core Components (Week 3-4)
├─ Cell editor with syntax highlighting
├─ Cell output display (text, table, error)
├─ Sidebar (metadata, trust policies)
├─ WORM ledger viewer

Phase 3: Animation Engine (Week 5-6)
├─ Canvas execution flow animation
├─ D3 dependency graph visualization
├─ Receipt chain animation
├─ Unicode glyph particle system
├─ Cryptographic seal effect

Phase 4: State & Integration (Week 7-8)
├─ NotebookStore event emitter
├─ Component state subscriptions
├─ Runtime bridge (WebSocket/HTTP)
├─ Cell execution orchestration
├─ Receipt seal integration

Phase 5: Polish & Testing (Week 9-10)
├─ Performance optimization (virtualization)
├─ Accessibility audit (WCAG 2.1 AA)
├─ Unit tests (80%+ coverage)
├─ Integration tests
├─ End-to-end tests (Playwright)

Phase 6: Deployment (Week 11-12)
├─ Production build optimization
├─ Browser compatibility testing
├─ Performance monitoring setup
├─ Documentation & examples
├─ Handoff to support team
```

---

## Integration Architecture

```
SOVEREIGN NOTEBOOK FRONTEND
         │
         ├─ Runtime Bridge (WebSocket)
         │  └─ /api/execute (POST)
         │  └─ /api/verify (GET)
         │  └─ /api/ledger (WS)
         │
         ├─ Isomorphic Shift Layer
         │  ├─ M1: Surface → Canonical
         │  ├─ M2: Canonical → Logic Term
         │  ├─ M3: Auth Logic → Runtime Command
         │  ├─ M5: Execution Event → Logic Event
         │  └─ M6: Event → Receipt (WORM seal)
         │
         ├─ Runtime Execution
         │  ├─ WebLLM (WASM inference)
         │  ├─ Tau Prolog (logic queries)
         │  └─ Ada Runtime (compiled code)
         │
         └─ WORM Ledger & Verification
            ├─ Receipt storage (blake3 chain)
            ├─ Ed25519 signature verification
            └─ Immutable audit trail

The frontend is **purely presentational**:
- No security logic in JavaScript
- All authority/verification on backend
- No key material in browser memory
- Transparent data flow to user
```

---

## Critical Files Reference

| File | Purpose | Size |
|------|---------|------|
| `SOVEREIGN_NOTEBOOK_UI_SPEC.md` | Complete design spec | 50KB |
| `SOVEREIGN_NOTEBOOK_FRONTEND_IMPL.md` | Implementation scaffold | 45KB |
| `SOVEREIGN_NOTEBOOK_ARCH_DIAGRAMS.md` | Visual architecture | 40KB |
| (future) `src/index.ts` | App entry point | 1KB |
| (future) `src/stores/notebook.store.ts` | State management | 10KB |
| (future) `src/components/notebook-container.ts` | Root component | 12KB |
| (future) `src/animation/execution-flow.ts` | Animation engine | 8KB |
| (future) `styles/global.css` | Design tokens | 3KB |
| (future) `vitest.config.ts` | Test configuration | 1KB |

---

## Getting Started (for Frontend Engineer)

### Step 1: Read the Specs (2-3 hours)
```bash
# Read in this order:
1. SOVEREIGN_NOTEBOOK_FRONTEND_IMPL.md (Part 1-2: Setup & Types)
2. SOVEREIGN_NOTEBOOK_UI_SPEC.md (§ 1-2: Layout & Components)
3. SOVEREIGN_NOTEBOOK_ARCH_DIAGRAMS.md (§ 1-2: Architecture & Execution)
```

### Step 2: Setup Project (30 minutes)
```bash
# Follow FRONTEND_IMPL.md Part 1-3
mkdir sovereign-notebook-frontend
cd sovereign-notebook-frontend
npm init -y
npm install vite typescript highlight.js d3
mkdir -p src/{components,animation,services,types,utils,stores}
```

### Step 3: Create Type Definitions (1 hour)
```bash
# Copy code from FRONTEND_IMPL.md § Part 2
# Create: src/types/cell.ts, src/types/receipt.ts, src/types/execution.ts
```

### Step 4: Build NotebookStore (2 hours)
```bash
# Copy NotebookStore from FRONTEND_IMPL.md § Part 3
# Create: src/stores/notebook.store.ts
# Write unit tests for store mutations
```

### Step 5: Start Web Components (4 hours)
```bash
# Create: src/components/notebook-container.ts
# Create: src/components/cell-editor.ts
# Create: src/components/cell-output.ts
# Test in browser with Vite dev server
```

### Step 6: Animation Engine (6 hours)
```bash
# Create: src/animation/execution-flow.ts
# Implement Canvas rendering loop
# Test particle spawning and arrow animation
```

### Step 7: Runtime Bridge (3 hours)
```bash
# Create: src/services/runtime-bridge.ts
# Wire WebSocket connection
# Test execution flow end-to-end
```

**Total Time**: ~20 hours to Phase 1 working prototype

---

## Design System Reference

### Color Palette (Dark Mode)
```css
--color-bg-primary: #070b1e;      /* Deep navy */
--color-bg-secondary: #0f0f2e;    /* Lighter navy */
--color-text-primary: #eef9ff;    /* Light cyan */
--color-text-secondary: #a0a7d0;  /* Muted blue */
--color-accent-cyan: #7ef9ff;     /* Bright cyan */
--color-accent-magenta: #ff79dc;  /* Magenta */
--color-accent-gold: #ffe98a;     /* Gold (seals) */
--color-error: #ff4fd8;           /* Error red */
--color-success: #00d9a3;         /* Success teal */
```

### Typography
```css
--font-mono: 'Fira Code', 'Courier New', monospace;
--font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-size-code: 14px;
--line-height-code: 1.6;
```

### Spacing Scale
```css
4px → 8px → 16px → 24px → 32px
 xs    sm    md    lg    xl
```

---

## Testing Strategy

### Unit Tests (Vitest)
```bash
test/components/notebook-cell.test.ts
test/components/cell-editor.test.ts
test/animation/execution-flow.test.ts
test/stores/notebook.store.test.ts
```
**Target**: 80%+ coverage

### Integration Tests
```bash
test/integration/execution-flow.test.ts
test/integration/state-bindings.test.ts
```

### E2E Tests (Playwright)
```bash
test/e2e/notebook.spec.ts
# Test full user workflows
```

---

## Performance Targets

| Metric | Target | Critical? |
|--------|--------|-----------|
| **Time to Interactive** | < 2s | Yes (on slow 3G) |
| **Animation FPS** | 60fps | Yes (smooth UX) |
| **Cell Editor Response** | < 100ms | Yes (typing feel) |
| **Execution Trace Animation** | < 16ms frame | Yes (60fps) |
| **Receipt Ledger Scroll** | < 100ms per item | Yes (virtualization) |
| **Bundle Size** | < 500KB | No (feature-rich) |
| **WCAG AA Pass Rate** | 100% | Yes (mandate) |

---

## Known Limitations & Future Enhancements

### Current Scope (v1.0)
- Single-user, single-notebook editing
- Sequential cell execution (no parallelism)
- Local state (no cloud sync)
- No collaborative editing
- No cell versioning/history

### Future Enhancements (v2.0+)
- [ ] Concurrent cell execution with thread pools
- [ ] Cloud sync (Cloudflare KV)
- [ ] Real-time collaboration (Yjs + WebSocket)
- [ ] Cell versioning (git-like history)
- [ ] Notebook templates & sharing
- [ ] Custom visualization plugins
- [ ] Terminal integration
- [ ] Multi-kernel support (Python, Julia, R)

---

## Troubleshooting & FAQs

### Q: Why vanilla Web Components instead of React?
A: Reduced dependency footprint, framework-agnostic WASM integration, easier cryptographic security model (no JSX abstraction layer).

### Q: Why Canvas instead of SVG for animations?
A: Canvas scales better for particle systems (100+ glyphs flowing simultaneously). SVG better for static graphs (D3 handles this).

### Q: Why no database in frontend?
A: All persistent state lives in backend WORM ledger. Frontend is ephemeral (reload-safe). Matches sovereign security model.

### Q: How do I handle authentication?
A: Frontend sends auth token in HTTP headers. Backend validates via OIDC/JWT. Frontend never stores secrets.

### Q: Can I run this on mobile?
A: Yes, responsive design breakpoints handle tablets/phones. Limited to ~50-100 cells on mobile (virtualization helps).

---

## Support & Handoff

### Documentation
- **Inline Comments**: Every component has JSDoc comments
- **README**: Each component folder has its own README
- **Examples**: `examples/` folder with common workflows
- **Demo**: Live demo at `http://localhost:5173` (Vite dev server)

### Questions?
- **Architecture**: Check ARCH_DIAGRAMS.md
- **Components**: Check UI_SPEC.md § 2
- **Implementation**: Check FRONTEND_IMPL.md
- **Styling**: Check UI_SPEC.md § 3

### Handoff Checklist
- [ ] All 3 spec documents reviewed
- [ ] Project setup complete (Vite, TypeScript)
- [ ] Type definitions created
- [ ] NotebookStore working
- [ ] First 3 Web Components functional
- [ ] Canvas animation prototype running
- [ ] Runtime bridge connected
- [ ] End-to-end test passing

---

## Success Criteria

### Frontend Engineer Success
✓ All 15 components working  
✓ 80%+ test coverage  
✓ 60fps animations  
✓ < 100ms cell execution feedback  
✓ WCAG 2.1 AA certified  
✓ < 500KB bundle size  

### Product Success
✓ Notebook usable with 100+ cells  
✓ Receipt ledger builds correctly  
✓ Execution traces visible in real-time  
✓ Theme toggle works smoothly  
✓ Error messages clear & actionable  

### User Success
✓ Can edit and run cells in < 30 seconds  
✓ Understands cell dependencies visually  
✓ Trusts WORM ledger integrity  
✓ Feels like a "sovereign" notebook (vs Jupyter)  

---

## Timeline

- **Design Complete**: 2026-07-27 ✓
- **Implementation Start**: 2026-07-28 (Monday)
- **Phase 1 Complete**: 2026-08-10
- **Phase 2 Complete**: 2026-08-24
- **Phase 3 Complete**: 2026-09-07
- **Phase 4 Complete**: 2026-09-21
- **Phase 5 Complete**: 2026-10-05
- **Production Release**: 2026-10-19

---

## Related Documentation

- **Backend Spec**: `/bob-orchestrator/README.md`
- **Isomorphic Shift Layer**: `/isomorphic-shift/docs/architecture.md`
- **WORM Ledger**: `/backend/dist/worm.d.ts`
- **Session Handoff**: `/SESSION_HANDOFF.md`

---

## Author & License

**Author**: Claude Code (Frontend/UX Engineer)  
**Version**: 1.0 (Complete)  
**Date**: 2026-07-27  
**Status**: ✓ DESIGN FINALIZED, READY FOR DEVELOPMENT

**License**: Same as parent repository (SnapKitty sovereign notebook)

---

**Document Finalized**: 2026-07-27 15:15 UTC  
**Ready for Handoff to Frontend Engineer**: ✓
