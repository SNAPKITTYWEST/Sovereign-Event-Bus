# SOVEREIGN NOTEBOOK — ARCHITECTURE DIAGRAMS & FLOWS

**Visual Architecture Reference**  
**Version**: 1.0  
**Date**: 2026-07-27

---

## 1. SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SOVEREIGN NOTEBOOK UI LAYER                     │
│  (Browser: Web Components, Canvas, SVG, EventEmitters)              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  Presentation    │  │  State           │  │  Animation       │  │
│  │  Components      │  │  Management      │  │  Engine          │  │
│  │  ─────────────   │  │  ─────────────   │  │  ─────────────   │  │
│  │  • Cell Editor   │  │  • NotebookStore │  │  • Execution     │  │
│  │  • Cell Output   │  │  • Event Emitter │  │    Flow (Canvas) │  │
│  │  • Sidebar       │  │  • Subscriptions │  │  • Dep Graph     │  │
│  │  • Ledger Viewer │  │  • Cell Cache    │  │    (D3)          │  │
│  │  • Header/Footer │  │  • Receipt List  │  │  • Receipt Chain │  │
│  │                  │  │                  │  │  • Unicode       │  │
│  └────────┬─────────┘  └────────┬─────────┘  │    Glyphs        │  │
│           │                    │             │  • Crypto Seal   │  │
│           └────────┬───────────┘             └────────┬─────────┘  │
│                    │                                  │             │
│         [User Input] │ [Data Binding]                │             │
│                    │ [Subscriptions]        [Animation Events]     │
│                    ▼                                  │             │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │         Runtime Bridge (WebSocket + HTTP)                   │   │
│  │  • Execution requests → /api/execute                        │   │
│  │  • Receipt queries → /api/verify                            │   │
│  │  • WORM ledger polling                                      │   │
│  └────────────────────────┬────────────────────────────────────┘   │
│                           │                                         │
└───────────────────────────┼─────────────────────────────────────────┘
                            │
                   [WebSocket/HTTP]
                            │
┌───────────────────────────┴─────────────────────────────────────────┐
│                        BACKEND LAYER                                │
│  (Rust + Prolog + Ada: Execution, Verification, WORM Sealing)      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  Isomorphic      │  │  Runtime         │  │  WORM Ledger     │  │
│  │  Shift Layer     │  │  Executor        │  │  & Verification  │  │
│  │  ─────────────   │  │  ─────────────   │  │  ─────────────   │  │
│  │  M1: Surface →   │  │  • WebLLM        │  │  • Receipt Gen   │  │
│  │    Canonical     │  │  • Tau Prolog    │  │  • WORM Chain    │  │
│  │  M2: Canonical → │  │  • Ada Runtime   │  │  • Ed25519 Sig   │  │
│  │    Logic Term    │  │  • Rust Executor │  │  • Blake3 Hash   │  │
│  │  M3: Auth Logic  │  │  • Error Handler │  │  • Chain Valid   │  │
│  │    → Runtime     │  │                  │  │  • Archive       │  │
│  │  M4-M8: others   │  │                  │  │                  │  │
│  │                  │  │                  │  │                  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. DATA FLOW: EXECUTION PIPELINE

```
USER ACTION: Click "Run" on Cell 1
│
▼
┌─────────────────────────────────────────────────────────┐
│ NotebookCell receives click event                        │
│ • Extracts source code from editor                       │
│ • Emits 'cell:execute' event                             │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ RuntimeBridge.executeCell(ExecutionRequest)             │
│ • cellId: "cell-001"                                    │
│ • source: "⚡ fn:1618"                                  │
│ • language: "emoji"                                     │
│ • dependencies: []                                      │
│ • executorAgent: "builder"                              │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ NotebookStore.setExecuting("cell-001")                  │
│ • cell.executionStatus = "running"                      │
│ • Emit 'cell:executing' event                           │
│ • Update UI: show spinner                               │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Animation Engine triggered                              │
│ • ExecutionFlowAnimator.startCell("cell-001")           │
│ • Show running indicator on canvas                      │
│ • Spawn unicode glyphs (λ, Ω, ∑)                        │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ HTTP POST /api/execute                                  │
│ Body: {                                                 │
│   cellId: "cell-001",                                   │
│   source: "⚡ fn:1618",                                 │
│   ...                                                   │
│ }                                                       │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ BACKEND: M1 → Canonical Instruction                     │
│ "⚡ fn:1618" → {verb: execute, args: [fn, 1618]}       │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ BACKEND: M2 → Logic Term                                │
│ logic_term(execute, [fn, 1618])                         │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ BACKEND: Authorization Check (Prolog)                   │
│ can_perform_shift(builder, execute, fn)?                │
│ ✓ YES → proceed to M3                                   │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ BACKEND: M3 → Runtime Command                           │
│ runtime_command(rust, execute_fn, [1618], {...})       │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ BACKEND: Execute                                         │
│ • WebLLM inference OR                                    │
│ • Tau Prolog query OR                                   │
│ • Ada runtime call                                      │
│ • Capture output                                        │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ BACKEND: M5 → Execution Event                           │
│ execution_event(hash_abc, ..., builder, execute, {      │
│   result: ok,                                           │
│   output: 42                                            │
│ })                                                      │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ BACKEND: M6 → Receipt Record (WORM seal)                │
│ receipt_record(hash_receipt, hash_abc, proof_hash,      │
│   authorized, worm_xyz, timestamp)                      │
│ • Ed25519 sign(blake3(event))                           │
│ • WORM chain append                                     │
│ • Immutable on ledger                                   │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│ HTTP Response 200 OK                                     │
│ {                                                       │
│   cellId: "cell-001",                                   │
│   status: "success",                                    │
│   output: { type: "text", data: "42" },                 │
│   executionTime: 125,                                   │
│   receiptId: "receipt-xyz",                             │
│   wormHash: "0xabc123..."                               │
│ }                                                       │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Frontend: RuntimeBridge receives response               │
│ • Parse JSON                                            │
│ • Call notebook.completeExecution()                     │
│ • Call notebook.addReceipt()                            │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ NotebookStore updates state                             │
│ • cell.executionStatus = "success"                      │
│ • cell.output = {type: "text", data: "42"}              │
│ • receipts.push(new receipt)                            │
│ • Emit 'cell:executed' event                            │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Component subscriptions trigger re-render               │
│ • NotebookCell displays output: "42"                    │
│ • WormLedger adds receipt entry                         │
│ • Remove execution spinner                              │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Animation Engine completes                              │
│ • ExecutionFlowAnimator.completeCell()                  │
│ • Show checkmark ✓ on canvas                            │
│ • Animate seal effect (rotating gold circle)            │
│ • Fade out unicode glyphs                               │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
USER SEES: Cell output "42" + Receipt in ledger + Seal animation
```

---

## 3. STATE MANAGEMENT FLOW

```
┌─────────────────────────────────────────────────────────┐
│                 NotebookStore (Singleton)               │
│                                                         │
│  cells: Map<cellId, Cell>                               │
│  receipts: ReceiptRecord[]                              │
│  listeners: Map<EventType, Set<Callback>>               │
│  metadata: NotebookMetadata                             │
│  isDirty: boolean                                       │
└─────────────────────────────────────────────────────────┘
                           ▲
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │ addCell()    │ │ updateCell() │ │ deleteCell() │
    └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
           │                │                │
           └────────────────┼────────────────┘
                            │
                     emit('cell:created')
                     emit('cell:updated')
                     emit('cell:deleted')
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               ▼
      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
      │ NotebookCell │ │ WormLedger   │ │ CellOutput   │
      │ component    │ │ component    │ │ component    │
      │              │ │              │ │              │
      │ re-renders   │ │ updates list │ │ displays     │
      │ when cell    │ │ when receipt │ │ when output  │
      │ changes      │ │ added        │ │ updated      │
      └──────────────┘ └──────────────┘ └──────────────┘

Pattern:
  Action → Store.method() → emit(event) → Subscribers → Re-render
```

---

## 4. COMPONENT TREE WITH REACTIVITY

```
notebook-container (root, subscribes to all events)
│
├─ notebook-header
│  ├─ notebook-title (displays metadata.title)
│  ├─ btn-run (triggers runAllCells)
│  ├─ btn-save (triggers saveNotebook)
│  └─ btn-export (exports notebook JSON)
│
├─ notebook-toolbar
│  ├─ language-selector
│  ├─ btn-add-cell
│  └─ search-bar
│
├─ notebook-layout (grid 3-column on desktop)
│  │
│  ├─ notebook-sidebar (left)
│  │  ├─ notebook-info
│  │  │  └─ displays: cell count, modified time
│  │  │
│  │  ├─ dependency-graph-mini
│  │  │  └─ mini D3 graph (click to highlight)
│  │  │
│  │  └─ trust-policies
│  │     └─ select executor agent
│  │
│  ├─ notebook-editor-area (center, flex: 1)
│  │  │
│  │  ├─ execution-trace-overlay
│  │  │  └─ Canvas element (animated flow)
│  │  │
│  │  ├─ notebook-cells (virtualized list)
│  │  │  │
│  │  │  └─ notebook-cell (repeated for each cell)
│  │  │     │  Subscribes to: notebook.subscribe('cell:updated')
│  │  │     │
│  │  │     ├─ cell-header
│  │  │     │  └─ displays: type icon, cell ID, execution status
│  │  │     │
│  │  │     ├─ cell-editor
│  │  │     │  └─ textarea + syntax highlighting (Highlight.js)
│  │  │     │
│  │  │     ├─ cell-controls
│  │  │     │  ├─ btn-run (emits 'cell:execute')
│  │  │     │  ├─ btn-delete (calls notebook.deleteCell)
│  │  │     │  └─ btn-move (reorder in notebook)
│  │  │     │
│  │  │     └─ cell-output (only if output exists)
│  │  │        └─ Subscribes to: notebook.subscribe('cell:executed')
│  │  │           Renders based on output.type:
│  │  │           • text → <pre>
│  │  │           • table → <table>
│  │  │           • graph → <svg> (D3)
│  │  │           • math → <div class="math"> (MathJax)
│  │  │           • error → <pre class="error">
│  │  │
│  │  └─ cell-separator
│  │     └─ btn-insert (insert cell below)
│  │
│  └─ worm-ledger (right)
│     │  Subscribes to: notebook.subscribe('receipt:sealed')
│     │
│     ├─ ledger-header
│     │  └─ "WORM Ledger" title + filter menu
│     │
│     ├─ receipt-list (scrollable)
│     │  │
│     │  └─ receipt-item (repeated, reverse-chronological)
│     │     ├─ receipt-header
│     │     │  ├─ receipt-id (truncated hash)
│     │     │  └─ receipt-status (sealed/verified/pending)
│     │     │
│     │     ├─ receipt-details (collapsible)
│     │     │  ├─ Full hash
│     │     │  ├─ Ed25519 signature
│     │     │  ├─ Timestamp
│     │     │  └─ Agent name
│     │     │
│     │     └─ receipt-actions
│     │        ├─ btn-verify (verify signature)
│     │        ├─ btn-copy (copy hash)
│     │        └─ btn-export (save receipt JSON)
│     │
│     └─ load-more-button
│        └─ pagination: show next 10 receipts
│
├─ dependency-graph-modal (hidden, click to show)
│  ├─ graph-canvas (full-screen D3 visualization)
│  ├─ graph-legend (explain edge types)
│  └─ graph-controls (zoom, pan, reset)
│
└─ notebook-footer
   ├─ execution-stats (total time, avg per cell)
   ├─ cell-count (active cells)
   ├─ runtime-status (connected/disconnected indicator)
   └─ connection-indicator (WebSocket status)
```

---

## 5. ANIMATION EVENT ORCHESTRATION

```
Receipt Sealing Animation Sequence:
─────────────────────────────────────

Time T+0ms:
  Receipt arrives from backend
  → notebook.addReceipt(receipt)
  → emit('receipt:sealed', receipt)
  → WormLedger component receives event
  → Create receipt DOM element (opacity: 0)

Time T+0ms → T+300ms:
  Fade-in animation (CSS):
    @keyframes fadeInScale {
      from { opacity: 0; transform: scale(0.95); }
      to { opacity: 1; transform: scale(1); }
    }
  Duration: 300ms
  Components: receipt-item

Time T+300ms → T+2000ms:
  Hash scroll animation (CSS):
    @keyframes scrollHash {
      from { transform: translateX(-100%); }
      to { transform: translateX(100%); }
    }
  Duration: 1.5s, repeat: 1
  Components: receipt-hash text

Time T+0ms → ∞:
  Glow pulse animation (CSS):
    @keyframes glowPulse {
      0%, 100% { box-shadow: 0 0 10px cyan; }
      50% { box-shadow: 0 0 30px magenta; }
    }
  Duration: 2s, repeat: infinite
  Components: receipt-status indicator

Time T+2000ms:
  Crypto seal animation (Canvas):
    ReceiptChainAnimator.animateSeal(receipt)
    • Draw rotating circle
    • Scroll blake3 hash around perimeter
    • Glow effect pulses
    • Duration: 3s

Animation Completion:
  User sees:
    [Receipt ID] [Sealed ✓]
     ↓
    (rotating seal with blake3 hash)
```

---

## 6. KEYBOARD & MOUSE INTERACTION FLOW

```
┌─────────────────────────────────┐
│  USER KEYBOARD SHORTCUTS         │
├─────────────────────────────────┤

Shift+Enter (in cell editor)
  ↓
CellEditor captures keydown event
  ↓
Dispatch 'cell:execute' CustomEvent (bubbles: true)
  ↓
NotebookCell catches event
  ↓
RuntimeBridge.executeCell()
  ↓
Animation + Backend execution


Ctrl+S (anywhere)
  ↓
Document.addEventListener('keydown')
  ↓
NotebookContainer.saveNotebook()
  ↓
notebook.markSaved()
  ↓
UI shows "Saved" toast


Ctrl+Z / Ctrl+Shift+Z
  ↓
CellEditor maintains undo stack (textarea.value history)
  ↓
Revert cell.source to previous value
  ↓
No re-execution unless user presses Run


Escape (in edit mode)
  ↓
CellEditor loses focus
  ↓
cell-editor.readonly = true (visual change)
  ↓
Keyboard shortcut mode re-enabled

─────────────────────────────────────

┌─────────────────────────────────┐
│  USER MOUSE INTERACTIONS         │
├─────────────────────────────────┤

Click cell
  ↓
CellEditor receives focus
  ↓
textarea.focus()
  ↓
Syntax highlighting updates
  ↓
Ready for input


Hover on receipt (ledger)
  ↓
Show tooltip: full hash + signature
  ↓
.receipt-item:hover → box-shadow glow


Right-click on cell
  ↓
Show context menu:
  ├─ Run
  ├─ Run and Advance
  ├─ Delete
  ├─ Duplicate
  ├─ Move Up/Down
  └─ Add Below


Drag receipt edge in dependency graph
  ↓
highlight-path animation:
  • Dim non-related nodes
  • Brighten path nodes
  • Animate edges


Click dependency graph node
  ↓
Jump to cell (scroll into view)
  ↓
Highlight cell border


Pinch zoom on mobile (dependency graph)
  ↓
D3 simulation zoom handler
  ↓
Scale + translate nodes
```

---

## 7. RESPONSIVE DESIGN BREAKPOINTS

```
Desktop (1440px+):
┌──────────────────────────────────────────────┐
│ HEADER                                       │
├──────────────┬────────────────┬──────────────┤
│ SIDEBAR      │   EDITOR       │   LEDGER     │
│ 200px        │   1fr          │   300px      │
│              │                │              │
│ • Info       │ • Cells        │ • Receipts   │
│ • Graph      │ • Trace        │ • Filter     │
│ • Trust      │ • Canvas       │              │
│              │                │              │
├──────────────┴────────────────┴──────────────┤
│ FOOTER                                       │
└──────────────────────────────────────────────┘

Tablet (768px - 1439px):
┌──────────────────────────────────┐
│ HEADER (compact)                 │
├──────────────────────────────────┤
│          TAB BAR                 │
│  [Editor] [Ledger] [Graph]       │
├──────────────────────────────────┤
│                                  │
│      MAIN CONTENT (full width)   │
│                                  │
│  • Cells (full width)            │
│  • Sidebar collapsed → drawer    │
│  • Ledger collapsed → drawer     │
│                                  │
├──────────────────────────────────┤
│ FOOTER                           │
└──────────────────────────────────┘

Mobile (< 768px):
┌────────────────────┐
│ HEADER (very      │
│  compact)          │
├────────────────────┤
│ TAB BAR            │
│ [Editor] [Ledger]  │
├────────────────────┤
│                    │
│ MAIN CONTENT       │
│ (single column)    │
│                    │
│ • Cells            │
│ • Metadata bottom  │
│   sheet (swipe up) │
│                    │
├────────────────────┤
│ FOOTER             │
└────────────────────┘
```

---

## 8. WORM LEDGER VERIFICATION CHAIN

```
Receipt 1 (Oldest)
│
├─ hash: H1 = blake3(event1)
├─ signature: S1 = ed25519_sign(H1, key1)
├─ chain_link: C1 = blake3(H1 + S1)
└─ previous_hash: null
   │
   ▼
Receipt 2
│
├─ hash: H2 = blake3(event2)
├─ signature: S2 = ed25519_sign(H2, key2)
├─ chain_link: C2 = blake3(H2 + S2 + C1)
└─ previous_hash: C1 ✓ (matches receipt 1)
   │
   ▼
Receipt 3
│
├─ hash: H3 = blake3(event3)
├─ signature: S3 = ed25519_sign(H3, key3)
├─ chain_link: C3 = blake3(H3 + S3 + C2)
└─ previous_hash: C2 ✓ (matches receipt 2)
   │
   ▼
Receipt N (Newest)
│
├─ hash: HN = blake3(eventN)
├─ signature: SN = ed25519_sign(HN, keyN)
├─ chain_link: CN = blake3(HN + SN + C(N-1))
└─ previous_hash: C(N-1) ✓ (matches receipt N-1)

Verification Algorithm:
─────────────────────────

for receipt in receipts {
  // Verify structure
  assert(receipt.previous_hash == previous_receipt.chain_link)
  
  // Verify signature
  assert(ed25519_verify(receipt.signature, receipt.hash, receipt.agent_key))
  
  // Verify chain continuity
  computed_link = blake3(receipt.hash + receipt.signature + receipt.previous_hash)
  assert(computed_link == receipt.chain_link)
}

Result: If all assertions pass → ✓ SEALED & VERIFIED
        If any fails → ✗ INTEGRITY VIOLATED
```

---

## 9. EXECUTION DEPENDENCY RESOLUTION

```
Input: 5 cells with dependencies

Cell 1: source="a = 10"           depends_on: []
Cell 2: source="b = a + 5"        depends_on: [1]
Cell 3: source="c = a * 2"        depends_on: [1]
Cell 4: source="d = b + c"        depends_on: [2, 3]
Cell 5: source="print(d)"         depends_on: [4]

Dependency Graph:
     Cell 1
      / \
     /   \
  Cell 2  Cell 3
     \   /
      \ /
      Cell 4
       |
      Cell 5

Execution Order (topological sort):
  [Cell 1, Cell 2, Cell 3, Cell 4, Cell 5]

Concurrent Execution Groups (possible):
  Batch 1: [Cell 1]
  Batch 2: [Cell 2, Cell 3]  (both depend only on Cell 1)
  Batch 3: [Cell 4]          (needs both Cell 2 & 3)
  Batch 4: [Cell 5]

Current Implementation: Sequential
(Can be optimized to concurrent batches with thread pool)

Error Handling:
  If Cell 1 fails:
    ✗ Cell 2 skipped (dependency failure)
    ✗ Cell 3 skipped (dependency failure)
    ✗ Cell 4 skipped (dependency failure)
    ✗ Cell 5 skipped (dependency failure)
  
  Result: Cell 1 error propagates to all dependents
```

---

## 10. THEME SWITCHING FLOW

```
User clicks theme toggle button
│
▼
ThemeManager.set('dark' | 'light')
│
├─ document.documentElement.setAttribute('data-theme', 'dark')
│
├─ localStorage.setItem('theme', 'dark')
│
└─ window.dispatchEvent(CustomEvent('theme-changed'))
   │
   ▼
CSS updates via CSS Cascading:
│
├─ [data-theme="dark"] { --color-bg-primary: #070b1e; }
│
├─ [data-theme="light"] { --color-bg-primary: #f8f9fa; }
│
▼
All components using CSS variables auto-update:
│
├─ background: var(--color-bg-primary) → new value
├─ color: var(--color-text-primary) → new value
├─ border: var(--color-accent-cyan) → new color
│
▼
No JavaScript re-render needed! (CSS Cascade handles it)

Browser reload:
│
▼
document.addEventListener('DOMContentLoaded')
│
▼
ThemeManager.get() reads localStorage
│
▼
Apply theme on initial load (prevents flash)
```

---

## 11. CANVAS RENDERING PIPELINE

```
RequestAnimationFrame Loop (60fps target)
│
├─ Time: T = now()
├─ Delta: dt = (T - lastT) / 1000
├─ lastT = T
│
▼
Update Phase:
├─ ExecutionFlowAnimator.update(dt)
│  ├─ particles.forEach(p => {
│  │   p.x += p.vx * dt
│  │   p.y += p.vy * dt
│  │   p.age += dt
│  │ })
│  └─ arrows.forEach(a => {
│      a.progress = (now - a.startTime) / a.duration
│    })
│
├─ ReceiptChainAnimator.update(dt)
│  └─ rotation += 0.05 (2s per rotation)
│
└─ DependencyGraphAnimator.update(dt)
   └─ force_simulation.tick()

Render Phase:
├─ ctx.clearRect(0, 0, width, height)
│
├─ ExecutionFlowAnimator.render()
│  ├─ drawArrows()
│  │  ├─ ctx.strokeStyle = gradient
│  │  ├─ ctx.lineTo(...)
│  │  └─ drawArrowhead()
│  │
│  └─ drawParticles()
│     ├─ ctx.font = '24px'
│     ├─ ctx.fillText(glyph, x, y)
│     └─ apply rotation + alpha
│
├─ ReceiptChainAnimator.render()
│  ├─ ctx.rotate(rotation)
│  ├─ ctx.arc(cx, cy, r, 0, 2π)
│  ├─ ctx.stroke()
│  └─ ctx.shadowBlur = 20 (glow)
│
└─ if (animating) requestAnimationFrame(...)

Performance Considerations:
├─ Use OffscreenCanvas for complex scenes
├─ Batch draw calls (group by style)
├─ Avoid ctx.save/restore in tight loops
├─ Pre-compute gradients/paths
├─ Clip rendering to visible area
└─ Profile with DevTools → Performance tab
```

---

## 12. ERROR RECOVERY FLOW

```
Runtime Error Detected (e.g., Cell 2 timeout)
│
▼
ExecutionResponse: {
  status: 'timeout',
  error: {
    code: 'EXECUTION_TIMEOUT',
    message: 'Cell execution exceeded 30s limit',
    traceback: '...'
  }
}
│
▼
RuntimeBridge catches error
│
├─ notebook.completeExecution(cellId, 'error', error_output, 0)
│
└─ emit('cell:executed', {cellId, status: 'error'})
   │
   ▼
CellOutput renders error:
│
├─ cell.output = {
│   type: 'error',
│   data: 'EXECUTION_TIMEOUT: Cell execution exceeded 30s limit\n\nTraceback:\n...'
│  }
│
├─ CSS class: .error → red text + monospace
│
└─ User can:
   ├─ Edit cell source
   ├─ Increase timeout
   ├─ Run again (Retry)
   ├─ Delete cell
   └─ See full error in browser console

Dependent Cells (Cell 3, Cell 4, ...):
│
├─ Cell 3 depends on Cell 2
├─ NOT auto-executed
├─ User must re-run Cell 2 first
├─ Then re-run dependent cells
│
└─ (Option: Add "Run Dependents" button)

Network Error (No Backend Connection):
│
├─ RuntimeBridge.executeCell() throws
├─ UI shows: "Connection Error: Unable to reach /api/execute"
├─ Show retry button
├─ Check WebSocket status indicator
└─ Allow offline editing (cells marked as pending)
```

---

**Document Finalized**: 2026-07-27 15:00 UTC  
**Ready for Implementation**: ✓
