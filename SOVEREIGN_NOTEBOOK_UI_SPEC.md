# SOVEREIGN NOTEBOOK UI & ANIMATION SPEC

**Frontend/UX Engineer Specification**  
**Version**: 1.0  
**Status**: DESIGN COMPLETE  
**Date**: 2026-07-27  
**Authority**: Jessica (jessi@snapkitty.com)

---

## Executive Summary

The Sovereign Notebook is a cryptographically-sealed, reactive notebook interface that bridges:
- **Cell Editing**: Code, Markdown, Math (EmojiCode, HolyC, Python, JavaScript, Ada)
- **Execution Flow**: Isomorphic transformation pipeline (M1→M2→M3→Runtime→M5→M6)
- **Receipt Ledger**: WORM-sealed execution records with Ed25519 signatures
- **Dependency Graph**: Visual data flow between cells
- **Responsive Animations**: Unicode glyphs, hash chains, cryptographic locks

**Design Philosophy**: Minimal framework, vanilla Web Components, Canvas/SVG for animation, reactive state binding. Dark mode primary with light mode support.

---

## 1. LAYOUT & PANEL ARCHITECTURE

### 1.1 Desktop Layout (1440px+)

```
┌──────────────────────────────────────────────────────────────────────┐
│  HEADER: Notebook Title | Run | Interrupt | Save | Export | Verify  │
├──────────────────────────────────────────────────────────────────────┤
│ TOOLBAR: [⚡ EmojiCode] [Python] [Ada] [Math] | 🔍 Search           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  MAIN CONTENT AREA (3 columns)                                        │
│                                                                        │
│  ┌─ LEFT SIDEBAR ────┬─ CENTER EDITOR ────────┬─ RIGHT PANEL ──────┐ │
│  │                   │                        │                    │ │
│  │ • Metadata        │  Cell 1 [CODE]        │ • WORM Ledger     │ │
│  │   - Cell count    │  ┌────────────────┐   │   ┌─────────────┐ │ │
│  │   - Depends on    │  │ ⚡ fn:1618     │   │   │ Receipt ID  │ │ │
│  │   - Trust level   │  └────────────────┘   │   │ ─────────── │ │ │
│  │                   │  ▶️ [Output]          │   │ Hash: 0xab  │ │ │
│  │ • Dep Graph       │                       │   │ Sig: Ed...  │ │ │
│  │   └─ Visual       │  Cell 2 [MARKDOWN]   │   │ Time: 10:30 │ │ │
│  │     grid          │  ┌────────────────┐   │   └─────────────┘ │ │
│  │                   │  │ # Results      │   │                    │ │
│  │ • Trust Policies  │  └────────────────┘   │ • Dependency Graph │ │
│  │   - Execute as    │                       │   (small visual)   │ │
│  │   - Verify with   │  Cell 3 [MATH]       │                    │ │
│  │   - Seal with     │  ┌────────────────┐   │ • Cell Cache      │ │
│  │                   │  │ ∑ λ(x)dx      │   │   - Hit ratio     │ │
│  │                   │  └────────────────┘   │   - Memory used   │ │
│  │                   │  ▶️ [Output]          │                    │ │
│  │                   │                       │                    │ │
│  └───────────────────┴────────────────────────┴────────────────────┘ │
│                                                                        │
├──────────────────────────────────────────────────────────────────────┤
│  FOOTER: Execution time | Cell count | Status | Connected to runtime│
└──────────────────────────────────────────────────────────────────────┘
```

### 1.2 Mobile Layout (< 768px)

```
┌─────────────────────────────┐
│ HEADER (compact)            │
├─────────────────────────────┤
│ TAB BAR: [Editor] [Ledger]  │
├─────────────────────────────┤
│                             │
│ MAIN CONTENT (single col)  │
│                             │
│ • Cell 1 (full width)       │
│ • Cell 2 (full width)       │
│                             │
├─────────────────────────────┤
│ BOTTOM SHEET: Metadata      │
└─────────────────────────────┘
```

---

## 2. UI COMPONENTS

### 2.1 Web Component Definitions

#### `<notebook-container>`

**Purpose**: Root container for entire notebook UI  
**Attributes**:
- `notebook-id` (string): UUID of notebook
- `mode` (enum): 'edit' | 'view' | 'locked'
- `theme` (enum): 'dark' | 'light'

**State**:
```typescript
interface NotebookContainerState {
  notebookId: string;
  title: string;
  cells: Cell[];
  executionQueue: ExecutionTask[];
  receipts: ReceiptRecord[];
  dependencyGraph: CellDependency[];
  metadata: {
    createdAt: number;
    modifiedAt: number;
    author: string;
    trustLevel: 'low' | 'medium' | 'high' | 'sovereign';
  };
}
```

**Events**:
- `cell:created` → new cell added
- `cell:executed` → cell completed execution
- `receipt:sealed` → receipt added to WORM
- `graph:updated` → dependency graph changed

---

#### `<notebook-cell>` (Base Class)

**Purpose**: Editable/viewable cell with multiple types  
**Attributes**:
- `cell-id` (string): UUID
- `cell-type` (enum): 'code' | 'markdown' | 'math'
- `language` (enum): 'emoji' | 'python' | 'holyc' | 'javascript' | 'ada'
- `readonly` (boolean): read-only mode

**Subcomponents**:
- `<notebook-cell-editor>` — editable textarea with syntax highlighting
- `<notebook-cell-output>` — rendered output display
- `<notebook-cell-controls>` — run/delete/move buttons

**State**:
```typescript
interface Cell {
  id: string;
  type: 'code' | 'markdown' | 'math';
  language: Language;
  source: string;
  output: CellOutput | null;
  executionTime: number; // ms
  dependsOn: string[]; // cell IDs
  metadata: {
    createdAt: number;
    executedAt: number | null;
    executedBy: string;
    proof: ProofStatus;
  };
  sealStatus: 'pending' | 'sealed' | 'verified' | 'revoked';
}

interface CellOutput {
  type: 'text' | 'table' | 'graph' | 'math' | 'error';
  data: any;
  hash: string; // blake3
  receiptId: string | null;
}
```

---

#### `<cell-editor>`

**Purpose**: Monaco-like syntax highlighting for code cells  
**Attributes**:
- `language` (enum): programming language
- `theme` (enum): 'dark' | 'light'

**Features**:
- Syntax highlighting via Highlight.js
- Line numbers
- Code folding
- Inline error markers
- Autocomplete hints (from semantic registry)
- Undo/redo

**Keyboard Bindings**:
- `Shift+Enter` → run this cell
- `Ctrl+Enter` → run and select next
- `Ctrl+/` → toggle comment
- `Tab` → indent (4 spaces)
- `Escape` → exit edit mode

---

#### `<cell-output>`

**Purpose**: Render cell execution results  
**Supported Types**:

```
TEXT OUTPUT
┌─────────────────────────────┐
│ Output: 42                  │
│ Type: integer               │
│ Hash: 0xabcd...             │
└─────────────────────────────┘

TABLE OUTPUT
┌─────────────────────────────┐
│ col1  | col2  | col3        │
│ ─────────────────────────   │
│ val1  | val2  | val3        │
│ val4  | val5  | val6        │
└─────────────────────────────┘

GRAPH OUTPUT
┌─────────────────────────────┐
│  (rendered via D3/SVG)      │
│  • Scatter plot             │
│  • Bar chart                │
│  • Network graph            │
└─────────────────────────────┘

MATH OUTPUT
┌─────────────────────────────┐
│  ∑ λ(x)dx = 1618 (sealed)  │
│  Verified by: Lean4 ✓      │
└─────────────────────────────┘
```

**Renderers**:
- Text: plain or markdown-rendered
- Table: HTML table with sortable columns
- Graph: D3/Canvas visualization
- Math: MathJax/KaTeX rendering
- Error: syntax highlighted traceback

---

#### `<notebook-sidebar>`

**Purpose**: Left metadata and navigation panel  
**Sections**:

1. **Notebook Info**
   - Title (editable)
   - Cell count
   - Last modified
   - Total execution time

2. **Cell List** (scrollable)
   - Quick jump to cell
   - Execution status icon
   - Dependency count

3. **Dependency Graph** (miniature)
   - Small SVG visualization
   - Highlight current cell
   - Click to jump

4. **Trust Policies**
   - Execute as: [agent name]
   - Verify with: [verifier]
   - Seal with: [key fingerprint]

---

#### `<worm-ledger>`

**Purpose**: Right panel showing receipt chain  
**Display**:

```
WORM LEDGER VIEWER
─────────────────────────────

 Receipt #1          [▼]
 ├─ ID: 0xfab1...
 ├─ Event: Cell 2 execute
 ├─ Agent: builder
 ├─ Status: ✓ sealed
 ├─ Time: 10:30:45
 ├─ Hash: 0x7a8b...
 └─ Sig: Ed25519(0x1234...)

 Receipt #2          [▼]
 ├─ ID: 0xfab2...
 ├─ Event: Cell 3 verify
 ├─ ...

 [Load More ↓]
```

**Features**:
- Expandable receipt details
- Verify signature button
- Export receipt as JSON
- Copy hash to clipboard
- Filter by status/agent

---

#### `<execution-trace>`

**Purpose**: Animation overlay showing live execution flow  
**Display**:

```
EXECUTION TRACE (Canvas overlay, semi-transparent)
─────────────────────────────────────────────────────

Cell 1 ──→ [λ λ λ] ──→ Cell 2 ──→ [✓] ──→ OUTPUT
 Running     (0.2s)      Queued          Ready

Legend:
 ──→ data flow (animated arrow)
 λ   unicode glyph (flowing)
 ✓   completion marker
```

---

#### `<cryptographic-stamp>`

**Purpose**: Animated WORM seal effect  
**Visual**:

```
 🔐 SEALED
  ╱─────╲
 │ blake3 │  (rotating, glowing)
  ╲─────╱
   worm↻
```

**Animation**:
- Rotating background every 2s
- Blake3 hash scrolls
- Glow effect pulses
- Ed25519 signature in tooltip

---

### 2.2 CSS Architecture

#### File Structure
```
styles/
├── global.css              # resets, tokens, dark/light theme
├── components/
│  ├── notebook-cell.css
│  ├── cell-editor.css
│  ├── cell-output.css
│  ├── notebook-sidebar.css
│  ├── worm-ledger.css
│  └── execution-trace.css
├── animations.css          # keyframe definitions
├── layout.css              # grid, flexbox layouts
└── theme/
   ├── dark.css
   └── light.css
```

#### Design Tokens (CSS Variables)

```css
/* Color Palette */
--color-bg-primary: #070b1e;      /* dark navy */
--color-bg-secondary: #0f0f2e;    /* lighter navy */
--color-text-primary: #eef9ff;    /* light cyan */
--color-text-secondary: #a0a7d0;  /* muted blue */
--color-accent-cyan: #7ef9ff;     /* bright cyan */
--color-accent-magenta: #ff79dc;  /* magenta */
--color-accent-gold: #ffe98a;     /* gold */
--color-error: #ff4fd8;           /* bright magenta */
--color-success: #00d9a3;         /* teal */
--color-warning: #ffd86b;         /* orange */

/* Typography */
--font-mono: 'Fira Code', 'Courier New', monospace;
--font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-size-code: 14px;
--font-size-label: 12px;
--font-size-body: 16px;
--line-height-code: 1.6;

/* Spacing */
--spacing-xs: 4px;
--spacing-sm: 8px;
--spacing-md: 16px;
--spacing-lg: 24px;
--spacing-xl: 32px;

/* Borders & Shadows */
--border-radius-sm: 4px;
--border-radius-md: 8px;
--border-radius-lg: 16px;
--shadow-sm: 0 2px 4px rgba(0,0,0,0.3);
--shadow-md: 0 8px 24px rgba(0,0,0,0.5);
--shadow-glow: 0 0 20px rgba(126,249,255,0.4);

/* Transitions */
--transition-fast: 150ms ease-out;
--transition-normal: 300ms ease-out;
--transition-slow: 600ms ease-out;
```

#### Component Styles (Example: Cell Editor)

```css
notebook-cell-editor {
  display: block;
  position: relative;
  background: var(--color-bg-secondary);
  border: 1px solid var(--color-accent-cyan);
  border-radius: var(--border-radius-md);
  overflow: hidden;
}

notebook-cell-editor .editor-wrapper {
  display: grid;
  grid-template-columns: auto 1fr;
  height: 200px;
  font-family: var(--font-mono);
  font-size: var(--font-size-code);
  line-height: var(--line-height-code);
}

notebook-cell-editor .line-numbers {
  background: var(--color-bg-primary);
  border-right: 1px solid var(--color-accent-cyan);
  padding: var(--spacing-sm);
  color: var(--color-text-secondary);
  user-select: none;
}

notebook-cell-editor .line-number {
  display: block;
  height: 1.6em;
  text-align: right;
  opacity: 0.5;
}

notebook-cell-editor textarea {
  background: transparent;
  color: var(--color-text-primary);
  border: none;
  outline: none;
  padding: var(--spacing-sm);
  font-family: inherit;
  font-size: inherit;
  resize: none;
  z-index: 2;
}

notebook-cell-editor .highlights {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  z-index: 1;
  overflow: hidden;
}

notebook-cell-editor .highlight-line {
  height: 1.6em;
  padding: var(--spacing-sm);
  font-family: var(--font-mono);
  white-space: pre;
  word-break: break-all;
}

/* Syntax highlighting */
.hljs-keyword { color: var(--color-accent-magenta); }
.hljs-string { color: var(--color-success); }
.hljs-number { color: var(--color-warning); }
.hljs-function { color: var(--color-accent-cyan); }
.hljs-comment { color: var(--color-text-secondary); opacity: 0.7; }

/* Focus state */
notebook-cell-editor:focus-within {
  box-shadow: 0 0 12px var(--color-accent-cyan);
  border-color: var(--color-accent-cyan);
}
```

---

## 3. ANIMATION ENGINE

### 3.1 Animation Categories

#### A. Execution Flow Animation

**Purpose**: Visualize data flowing between cells  
**Implementation**: Canvas + requestAnimationFrame

```javascript
class ExecutionFlowAnimator {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.particles = []; // flowing glyphs
    this.arrows = [];    // connection arrows
    this.isAnimating = false;
  }

  startExecution(fromCell, toCell) {
    // Start arrow from fromCell to toCell
    // Spawn unicode glyphs flowing along path
    // Duration: execution time + 0.5s decay
  }

  completeExecution(cellId) {
    // Show checkmark at cell
    // Fade out incoming arrows
    // Seal indicator appears
  }

  animate() {
    // Update particle positions
    // Render arrows and particles
    // Handle collisions/bunching
    if (this.isAnimating) requestAnimationFrame(() => this.animate());
  }
}
```

**Visual Details**:
- Arrow color: cyan to magenta gradient
- Unicode glyphs: λ, Ω, ∑, ⊕, φ, ∞ (50px size, semi-transparent)
- Speed: 200px/sec
- Trail effect: 0.3s fade tail

---

#### B. Dependency Graph Animation

**Purpose**: Show data dependencies between cells  
**Implementation**: D3.js force-directed graph or custom SVG

```
 Cell1 ─────┐
            ├─→ Cell3 ─→ Cell5
 Cell2 ─────┤             ↓
            └─→ Cell4 ────┘
```

**Features**:
- Nodes: circles labeled with cell ID
- Edges: directed arrows
- Hover: highlight path to/from cell
- Click: jump to cell
- Animation: smooth force simulation

**Code Example**:
```javascript
class DependencyGraphVisualizer {
  constructor(svgElement) {
    this.svg = d3.select(svgElement);
    this.nodes = [];
    this.links = [];
    this.simulation = null;
  }

  update(cells, dependencies) {
    // Convert cells and dependencies to nodes/links
    // Run force simulation
    // Bind data and render
    // Add hover/click handlers
  }

  highlightPath(cellId) {
    // Dim non-related nodes
    // Highlight nodes on dependency path
    // Animate edges along path
  }
}
```

---

#### C. Receipt Chain Animation

**Purpose**: Visualize hash chain and sealing  
**Implementation**: SVG + Canvas for effects

```
Hash1 ──→ [blake3] ──→ Hash2 ──→ [blake3] ──→ Hash3
  ↓                      ↓                      ↓
[Ed25519]            [Ed25519]             [Ed25519]
  ↓                      ↓                      ↓
Sig1                  Sig2                  Sig3 [SEALED ✓]
```

**Animation Sequence**:
1. New receipt appears (fade in)
2. Hash scrolls left-to-right (1.5s)
3. Blake3 badge spins (rotation 360°)
4. Ed25519 signature glows (pulse effect)
5. Sealed checkmark animates (scale up)

**Code Structure**:
```javascript
class ReceiptChainAnimator {
  constructor(containerElement) {
    this.container = containerElement;
    this.receipts = []; // Array of ReceiptRecord
  }

  addReceipt(receipt) {
    // Create receipt element
    // Animate fade-in + scale
    // Animate hash scroll
    // Animate signature glow
    // Add to receipts array
  }

  animateHash(hashElement, hashValue) {
    // Scroll hash characters left-to-right
    // Duration: 1.5s
    // Monospace font, cyan color
  }

  animateSignature(sigElement) {
    // Glow pulse effect
    // Duration: 2s, repeat
    // Color: gold to magenta
  }
}
```

---

#### D. Unicode Glyph Animation

**Purpose**: Flowing mathematical symbols through cells  
**Implementation**: Canvas particles

```javascript
class UnicodeGlyphAnimator {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.glyphs = ['λ', 'Ω', '∑', '⊕', 'φ', '∞', '↔', '⇄', '∷', '⊗'];
  }

  spawnGlyph(startCell, endCell, duration) {
    // Create glyph particle
    // Interpolate position from start to end over duration
    // Fade in/out at edges
    // Rotate glyph during flight
  }

  render() {
    // Clear canvas
    // For each active glyph:
    //   - Compute position
    //   - Rotate based on velocity
    //   - Draw with alpha
    //   - Remove if expired
  }
}
```

**Glyph Semantics**:
- λ: lambda (function)
- Ω: omega (loop)
- ∑: summation
- ⊕: XOR operation
- φ: golden ratio
- ∞: infinity
- ↔: bidirectional
- ⇄: reversible

---

#### E. Cryptographic Seal Animation

**Purpose**: Rotating WORM seal effect on sealed cells  
**Implementation**: Canvas 2D transforms

```javascript
class CryptoSealAnimator {
  constructor(canvas, receiptId) {
    this.canvas = canvas;
    this.receiptId = receiptId;
    this.rotation = 0;
  }

  animate() {
    this.ctx.save();
    
    // Draw rotating circle
    this.ctx.translate(centerX, centerY);
    this.ctx.rotate(this.rotation);
    this.ctx.strokeStyle = 'rgba(255,233,138,0.8)';
    this.ctx.lineWidth = 3;
    this.ctx.beginPath();
    this.ctx.arc(0, 0, 30, 0, Math.PI * 2);
    this.ctx.stroke();
    
    // Draw scrolling hash
    this.ctx.rotate(-this.rotation);
    this.ctx.font = '12px monospace';
    this.ctx.fillStyle = 'rgba(255,233,138,0.6)';
    this.ctx.textAlign = 'center';
    this.ctx.fillText(this.receiptId.slice(0, 8) + '...', 0, -45);
    
    // Draw glow effect
    this.ctx.shadowColor = 'rgba(255,233,138,0.4)';
    this.ctx.shadowBlur = 20;
    this.ctx.arc(0, 0, 35, 0, Math.PI * 2);
    this.ctx.stroke();
    
    this.ctx.restore();
    
    this.rotation += 0.05; // ~2s per rotation
    requestAnimationFrame(() => this.animate());
  }
}
```

**Visual Appearance**:
- Rotating gold circle
- Blake3 hash scrolls around perimeter
- Inner glow pulses
- Semi-transparent overlay on cell

---

### 3.2 Keyframe Definitions (CSS)

```css
@keyframes fadeInScale {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes glowPulse {
  0%, 100% {
    box-shadow: 0 0 10px var(--color-accent-cyan);
  }
  50% {
    box-shadow: 0 0 30px var(--color-accent-magenta);
  }
}

@keyframes scrollHash {
  from {
    transform: translateX(-100%);
  }
  to {
    transform: translateX(100%);
  }
}

@keyframes rotateSeal {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@keyframes flowingGlyph {
  0% {
    opacity: 0;
    transform: translate(0, 0);
  }
  10% {
    opacity: 1;
  }
  90% {
    opacity: 1;
  }
  100% {
    opacity: 0;
    transform: translate(var(--distance), 0);
  }
}

@keyframes highlightBorder {
  0%, 100% {
    border-color: var(--color-accent-cyan);
  }
  50% {
    border-color: var(--color-accent-magenta);
  }
}
```

---

## 4. STATE MANAGEMENT

### 4.1 Reactive State Architecture

**Pattern**: Simple event emitter + reactive getters

```typescript
class NotebookStore {
  private cells: Map<string, Cell> = new Map();
  private receipts: ReceiptRecord[] = [];
  private listeners: Map<string, Set<Callback>> = new Map();
  
  // Observable properties (via Proxy)
  public state: {
    cells: Cell[];
    receipts: ReceiptRecord[];
    executionQueue: ExecutionTask[];
    selectedCellId: string | null;
  };

  subscribe(event: string, callback: Callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
    return () => this.listeners.get(event)!.delete(callback);
  }

  emit(event: string, data?: any) {
    this.listeners.get(event)?.forEach(cb => cb(data));
  }

  // Mutations
  addCell(cell: Cell) {
    this.cells.set(cell.id, cell);
    this.emit('cell:created', cell);
  }

  updateCellOutput(cellId: string, output: CellOutput) {
    const cell = this.cells.get(cellId);
    if (cell) {
      cell.output = output;
      this.emit('cell:updated', { cellId, output });
    }
  }

  addReceipt(receipt: ReceiptRecord) {
    this.receipts.push(receipt);
    this.emit('receipt:sealed', receipt);
  }

  // Queries
  getCellDependencies(cellId: string): string[] {
    const cell = this.cells.get(cellId);
    return cell?.dependsOn || [];
  }

  getDependencyGraph(): CellDependency[] {
    return Array.from(this.cells.values()).flatMap(cell =>
      cell.dependsOn.map(depId => ({ from: depId, to: cell.id }))
    );
  }

  getExecutionOrder(): string[] {
    // Topological sort of dependency graph
    const visited = new Set<string>();
    const order: string[] = [];

    const visit = (id: string) => {
      if (visited.has(id)) return;
      visited.add(id);
      const cell = this.cells.get(id);
      cell?.dependsOn.forEach(depId => visit(depId));
      order.push(id);
    };

    this.cells.forEach((_, id) => visit(id));
    return order;
  }
}

// Global singleton
export const notebook = new NotebookStore();
```

### 4.2 Component State Binding

**Pattern**: Web Components with reactive properties

```typescript
class NotebookCell extends HTMLElement {
  private _state: Cell = null;
  private unsubscribe: (() => void)[] = [];

  connectedCallback() {
    // Subscribe to cell updates
    this.unsubscribe.push(
      notebook.subscribe('cell:updated', (data) => {
        if (data.cellId === this._state.id) {
          this.render();
        }
      })
    );

    // Initial render
    this.render();
  }

  disconnectedCallback() {
    // Clean up subscriptions
    this.unsubscribe.forEach(fn => fn());
  }

  set state(cell: Cell) {
    this._state = cell;
    this.render();
  }

  get state(): Cell {
    return this._state;
  }

  private render() {
    // Update DOM based on state
    this.innerHTML = `
      <div class="cell">
        <div class="cell-header">
          ${this._state.type === 'code' ? '⚡' : '📝'} ${this._state.id}
        </div>
        <div class="cell-editor">
          ${this._state.source}
        </div>
        ${this._state.output ? `
          <div class="cell-output">
            ${this.renderOutput(this._state.output)}
          </div>
        ` : ''}
      </div>
    `;
  }

  private renderOutput(output: CellOutput): string {
    switch (output.type) {
      case 'text': return `<pre>${escapeHtml(output.data)}</pre>`;
      case 'table': return this.renderTable(output.data);
      case 'math': return `<div class="math">${output.data}</div>`;
      case 'error': return `<div class="error">${escapeHtml(output.data)}</div>`;
      default: return '';
    }
  }
}

customElements.define('notebook-cell', NotebookCell);
```

---

## 5. INTEGRATION POINTS

### 5.1 Runtime Communication

**Channel**: WebSocket or HTTP POST

```typescript
interface ExecutionRequest {
  cellId: string;
  source: string;
  language: Language;
  dependencies: string[];
  executorAgent: 'builder' | 'oracle' | 'sentinel';
}

interface ExecutionResponse {
  cellId: string;
  status: 'running' | 'success' | 'error' | 'timeout';
  output: CellOutput;
  executionTime: number;
  receiptId: string;
  wormHash: string;
}

class RuntimeBridge {
  async executeCell(req: ExecutionRequest): Promise<ExecutionResponse> {
    const response = await fetch('/api/execute', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req),
    });

    const data = await response.json() as ExecutionResponse;
    
    // Update notebook state
    notebook.updateCellOutput(req.cellId, data.output);
    notebook.addReceipt({
      id: data.receiptId,
      eventId: req.cellId,
      hash: data.wormHash,
      timestamp: Date.now(),
    });

    return data;
  }

  async verifyReceipt(receiptId: string): Promise<boolean> {
    const response = await fetch(`/api/verify/${receiptId}`);
    return response.ok;
  }
}

export const runtime = new RuntimeBridge();
```

### 5.2 Animation Event Hooks

```typescript
// Listen to execution events and trigger animations
notebook.subscribe('cell:executing', (cellId) => {
  executionAnimator.startCell(cellId);
});

notebook.subscribe('cell:updated', ({ cellId, output }) => {
  executionAnimator.completeCell(cellId);
  
  // Update dependent cells' incoming arrows
  const deps = notebook.getDependencyGraph();
  deps.filter(d => d.from === cellId).forEach(d => {
    executionAnimator.startArrow(cellId, d.to);
  });
});

notebook.subscribe('receipt:sealed', (receipt) => {
  receiptAnimator.addReceipt(receipt);
});
```

---

## 6. INTERACTION PATTERNS

### 6.1 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Shift+Enter` | Run current cell |
| `Ctrl+Enter` | Run and advance |
| `Ctrl+S` | Save notebook |
| `Ctrl+Z` / `Ctrl+Shift+Z` | Undo / Redo |
| `Ctrl+/` | Toggle comment |
| `Ctrl+H` | Open find/replace |
| `Ctrl+L` | Focus ledger |
| `Escape` | Exit edit mode |
| `Cmd+Click` | Multi-select cells |
| `Alt+Up/Down` | Move cell |

### 6.2 Mouse Gestures

- **Drag cell**: Reorder in notebook
- **Hover receipt**: Show full hash in tooltip
- **Right-click cell**: Context menu (delete/clone/move/seal)
- **Hover edge in graph**: Highlight dependency path
- **Click node in graph**: Jump to cell

### 6.3 Touch Gestures (Mobile)

- **Tap cell**: Enter edit mode
- **Swipe left**: Reveal delete/options
- **Pinch**: Zoom dependency graph
- **Long-press**: Context menu

---

## 7. DARK MODE & LIGHT MODE

### 7.1 Theme Variables

**Dark Theme** (default):
```css
[data-theme="dark"] {
  --color-bg-primary: #070b1e;
  --color-bg-secondary: #0f0f2e;
  --color-text-primary: #eef9ff;
  --color-accent-cyan: #7ef9ff;
}
```

**Light Theme**:
```css
[data-theme="light"] {
  --color-bg-primary: #f8f9fa;
  --color-bg-secondary: #ffffff;
  --color-text-primary: #1a1a2e;
  --color-accent-cyan: #0066cc;
}
```

### 7.2 Theme Switching

```typescript
class ThemeManager {
  static set(theme: 'dark' | 'light') {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
    
    // Notify all listeners
    window.dispatchEvent(new CustomEvent('theme-changed', { detail: theme }));
  }

  static get(): 'dark' | 'light' {
    return localStorage.getItem('theme') as any || 'dark';
  }

  static auto() {
    const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    this.set(isDark ? 'dark' : 'light');
  }
}
```

---

## 8. PERFORMANCE OPTIMIZATION

### 8.1 Virtualization

For notebooks with 100+ cells:
- Only render visible cells in viewport
- Use `IntersectionObserver` to detect visibility
- Keep execution trace canvas at fixed size

```typescript
class VirtualNotebook {
  constructor(container: HTMLElement) {
    this.container = container;
    this.visibleRange = { start: 0, end: 10 };
    this.cellHeight = 200;
    
    this.observer = new IntersectionObserver(
      (entries) => this.updateVisibleRange(entries),
      { rootMargin: '200px' }
    );
  }

  render(cells: Cell[]) {
    const startIdx = Math.max(0, Math.floor(this.container.scrollTop / this.cellHeight) - 2);
    const endIdx = Math.min(cells.length, startIdx + 12);
    
    this.container.innerHTML = cells
      .slice(startIdx, endIdx)
      .map(cell => `<notebook-cell cell-id="${cell.id}"></notebook-cell>`)
      .join('');
  }
}
```

### 8.2 Canvas Optimization

- Use `OffscreenCanvas` for animations
- Render only changed regions
- Batch DOM updates

```javascript
class OptimizedAnimationEngine {
  constructor() {
    this.offscreen = new OffscreenCanvas(1440, 900);
    this.ctx = this.offscreen.getContext('2d');
    this.mainCanvas = document.querySelector('canvas');
  }

  render() {
    // Clear only changed regions
    this.ctx.clearRect(0, 0, 1440, 900);
    
    // Render to offscreen
    this.drawParticles();
    this.drawArrows();
    
    // Transfer to main canvas
    const bitmap = this.offscreen.convertToImageBitmap();
    const ctxMain = this.mainCanvas.getContext('2d');
    ctxMain.drawImage(bitmap, 0, 0);
  }
}
```

---

## 9. ACCESSIBILITY

### 9.1 WCAG 2.1 AA Compliance

- **Semantic HTML**: Use proper heading hierarchy
- **Color Contrast**: All text ≥ 4.5:1 WCAG AA ratio
- **Keyboard Navigation**: All interactive elements keyboard-accessible
- **Screen Reader Support**: ARIA labels on animations, aria-live regions for status

### 9.2 ARIA Annotations

```html
<notebook-cell role="region" aria-label="Code cell 1" aria-live="polite">
  <div class="cell-header" aria-label="Cell 1: Execute status">
    ⚡ Cell 1
  </div>
  <cell-editor aria-label="Code editor"></cell-editor>
  <button aria-label="Run cell 1" aria-controls="cell-1-output">▶ Run</button>
  <cell-output id="cell-1-output" aria-live="assertive" aria-atomic="true"></cell-output>
</notebook-cell>
```

---

## 10. TESTING STRATEGY

### 10.1 Unit Tests (Vitest)

```typescript
// test/components/notebook-cell.test.ts
import { describe, it, expect } from 'vitest';
import { NotebookCell } from '../../src/components/notebook-cell';

describe('NotebookCell', () => {
  it('renders cell with code content', () => {
    const cell = document.createElement('notebook-cell');
    cell.state = {
      id: 'test-1',
      type: 'code',
      language: 'python',
      source: 'print("hello")',
      output: null,
      dependsOn: [],
      metadata: { createdAt: Date.now() },
    };
    
    expect(cell.innerHTML).toContain('print("hello")');
  });

  it('displays output when available', () => {
    const cell = document.createElement('notebook-cell');
    cell.state = {
      id: 'test-2',
      type: 'code',
      output: { type: 'text', data: 'hello' },
      // ... other props
    };
    
    expect(cell.innerHTML).toContain('hello');
  });
});
```

### 10.2 Integration Tests

```typescript
// test/integration/execution-flow.test.ts
import { notebook, runtime } from '../../src';

describe('Execution Flow', () => {
  it('executes cell and updates receipt ledger', async () => {
    const cell: Cell = {
      id: 'int-test-1',
      type: 'code',
      language: 'python',
      source: 'x = 42',
      output: null,
      dependsOn: [],
      metadata: { createdAt: Date.now() },
    };

    notebook.addCell(cell);
    const response = await runtime.executeCell({
      cellId: 'int-test-1',
      source: 'x = 42',
      language: 'python',
      dependencies: [],
      executorAgent: 'builder',
    });

    expect(response.status).toBe('success');
    expect(notebook.state.receipts.length).toBe(1);
  });
});
```

---

## 11. COMPONENT HIERARCHY

```
notebook-container
├── notebook-header
│   ├── notebook-title (editable)
│   ├── execution-controls (run/interrupt/save)
│   ├── export-menu
│   └── theme-switcher
├── notebook-toolbar
│   ├── language-selector
│   ├── cell-add-button
│   └── search-bar
├── notebook-layout (3-column grid)
│   ├── notebook-sidebar
│   │   ├── notebook-info
│   │   ├── cell-list (virtualized)
│   │   ├── dependency-graph-mini
│   │   └── trust-policies
│   ├── notebook-editor-area
│   │   ├── execution-trace-overlay (canvas)
│   │   └── notebook-cells (virtualized list)
│   │       ├── notebook-cell (repeated)
│   │       │   ├── cell-header
│   │       │   ├── cell-editor
│   │       │   ├── cell-controls
│   │       │   └── cell-output
│   │       └── cell-separator
│   └── worm-ledger
│       ├── ledger-header
│       ├── receipt-list (scrollable)
│       │   ├── receipt-item (repeated)
│       │   │   ├── receipt-header
│       │   │   ├── receipt-details (collapsible)
│       │   │   └── receipt-actions
│       │   └── load-more-button
│       └── ledger-filter
├── dependency-graph-viewer (modal, full-screen)
│   ├── graph-canvas
│   ├── graph-legend
│   └── graph-controls
└── notebook-footer
    ├── execution-stats
    ├── cell-count
    ├── runtime-status
    └── connection-indicator
```

---

## 12. DEVELOPMENT ROADMAP

### Phase 1: Foundation (Week 1-2)
- [ ] Web Component definitions (base classes)
- [ ] CSS architecture and design tokens
- [ ] Dark/light theme support
- [ ] Responsive layout (desktop + mobile)

### Phase 2: Core Components (Week 3-4)
- [ ] Cell editor with syntax highlighting
- [ ] Cell output display (text, table, error)
- [ ] Sidebar with metadata browser
- [ ] WORM ledger viewer

### Phase 3: Animation Engine (Week 5-6)
- [ ] Execution flow animation (Canvas)
- [ ] Dependency graph visualization (D3)
- [ ] Receipt chain animation
- [ ] Unicode glyph particles

### Phase 4: State & Integration (Week 7-8)
- [ ] Reactive state management
- [ ] Runtime communication bridge
- [ ] Keyboard/mouse interactions
- [ ] Error handling and recovery

### Phase 5: Polish & Testing (Week 9-10)
- [ ] Performance optimization (virtualization)
- [ ] Accessibility audit (WCAG 2.1 AA)
- [ ] Unit tests (80%+ coverage)
- [ ] Integration tests
- [ ] End-to-end tests

### Phase 6: Deployment (Week 11-12)
- [ ] Production build and optimization
- [ ] Performance monitoring
- [ ] Browser compatibility testing
- [ ] Documentation and examples

---

## 13. FILE STRUCTURE

```
frontend/
├── index.html                      # Entry point
├── styles/
│   ├── global.css
│   ├── variables.css              # Design tokens
│   ├── animations.css
│   ├── layout.css
│   ├── theme/
│   │   ├── dark.css
│   │   └── light.css
│   └── components/
│       ├── notebook-cell.css
│       ├── cell-editor.css
│       ├── cell-output.css
│       ├── notebook-sidebar.css
│       ├── worm-ledger.css
│       └── execution-trace.css
├── src/
│   ├── index.ts                   # App entry
│   ├── store/
│   │   ├── notebook.store.ts      # Reactive state
│   │   └── theme.store.ts
│   ├── components/
│   │   ├── notebook-container.ts
│   │   ├── notebook-cell.ts
│   │   ├── cell-editor.ts
│   │   ├── cell-output.ts
│   │   ├── notebook-sidebar.ts
│   │   ├── worm-ledger.ts
│   │   └── notebook-header.ts
│   ├── animation/
│   │   ├── execution-flow.ts
│   │   ├── dependency-graph.ts
│   │   ├── receipt-chain.ts
│   │   ├── unicode-glyphs.ts
│   │   └── crypto-seal.ts
│   ├── services/
│   │   ├── runtime-bridge.ts      # API client
│   │   ├── theme-manager.ts
│   │   └── keyboard-handler.ts
│   ├── types/
│   │   ├── cell.ts
│   │   ├── receipt.ts
│   │   └── execution.ts
│   └── utils/
│       ├── dom-utils.ts
│       ├── animation-utils.ts
│       └── format-utils.ts
├── test/
│   ├── components/
│   │   └── notebook-cell.test.ts
│   ├── animation/
│   │   └── execution-flow.test.ts
│   ├── integration/
│   │   └── execution-flow.test.ts
│   └── e2e/
│       └── notebook.spec.ts
├── vitest.config.ts
├── tsconfig.json
├── package.json
└── README.md
```

---

## 14. KEY DESIGN DECISIONS

| Decision | Rationale |
|----------|-----------|
| **Web Components** (not React/Vue) | Lightweight, framework-agnostic, WASM-ready |
| **Canvas animations** | Better performance than DOM for particle systems |
| **CSS Variables for theming** | Dynamic theme switching without JS overhead |
| **D3 for graphs** | Mature, battle-tested force-directed layout |
| **Event emitter pattern** | Simple, explicit, easy to debug |
| **Virtualization for large notebooks** | Handle 1000+ cells efficiently |
| **Dark mode primary** | Sovereign aesthetic, reduced eye strain |
| **WCAG 2.1 AA from start** | Accessibility is not an afterthought |
| **TypeScript throughout** | Type safety, better IDE support, self-documenting |
| **Monospace Unicode symbols** | Aesthetic + semantic meaning for glyphs |

---

## 15. SUCCESS METRICS

- **Performance**: Animation frame rate ≥ 60fps (Cell 6 animation engine)
- **Responsiveness**: Cell execution trace appears within 100ms
- **Accessibility**: 100% keyboard navigable, 0 WCAG AA violations
- **Code Quality**: ≥80% test coverage, <10 code smells
- **User Experience**: Task completion time ≤ 5 minutes for common workflows

---

## APPENDIX A: SVG Animation Examples

See: `/WORM.svg` and `rowm_worm_morphing_notebook.svg` for reference animations

### WORM.svg Features:
- Rotating dashed border frame
- Animated Unicode streams (bidirectional)
- Particle glyph markers
- Notebook container with grid background
- Sealed cryptographic stamp
- Matrix-like aesthetic

---

## APPENDIX B: Integration with Isomorphic Shift Layer

The UI bridges the notebook to the formal isomorphic shift system:

```
User Input (EmojiCode cell)
         ↓
    M1: SurfaceInstruction → CanonicalInstruction [UI renders this]
         ↓
    M2: CanonicalInstruction → LogicTerm [UI queries from store]
         ↓
    M3: AuthorizedLogicDecision → RuntimeCommand [Animation triggers]
         ↓
   EXECUTION [Receipt LED indicator shows "running"]
         ↓
    M5: ExecutionEvent → LogicEventFact [Animation completes]
         ↓
    M6: ExecutionEvent → ReceiptRecord [WORM ledger updates]
         ↓
User sees: Output + Receipt + Seal animation
```

The UI is **purely presentational** — all authority/verification/sealing happens in the backend Prolog + Rust layer.

---

**Document Finalized**: 2026-07-27 14:30 UTC  
**Next Review**: After Phase 1 completion
