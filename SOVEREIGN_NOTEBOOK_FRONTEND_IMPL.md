# SOVEREIGN NOTEBOOK — FRONTEND IMPLEMENTATION GUIDE

**Implementation Scaffold & Code Examples**  
**Version**: 1.0  
**Status**: READY FOR DEVELOPMENT  
**Target Framework**: Vanilla TypeScript + Web Components  
**Build Tool**: Vite or esbuild

---

## PART 1: PROJECT SETUP

### Step 1: Initialize Project Structure

```bash
mkdir sovereign-notebook-frontend
cd sovereign-notebook-frontend

# Create directory structure
mkdir -p src/{components,animation,services,types,utils,stores}
mkdir -p styles/{components,theme}
mkdir -p test/{components,animation,integration,e2e}
mkdir -p public/assets

# Initialize package.json
npm init -y
```

### Step 2: Install Dependencies

```json
{
  "name": "sovereign-notebook-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "preview": "vite preview",
    "lint": "eslint src/**/*.ts"
  },
  "dependencies": {
    "highlight.js": "^11.9.0",
    "d3": "^7.8.0",
    "mathjax": "^3.2.2"
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vitest": "^1.1.0",
    "@vitest/ui": "^1.1.0",
    "@types/d3": "^7.4.0",
    "eslint": "^8.56.0",
    "prettier": "^3.1.0"
  }
}
```

### Step 3: TypeScript Configuration

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

---

## PART 2: CORE TYPE DEFINITIONS

### File: `src/types/cell.ts`

```typescript
export type CellType = 'code' | 'markdown' | 'math' | 'raw';
export type Language = 
  | 'emoji' 
  | 'python' 
  | 'javascript' 
  | 'typescript'
  | 'holyc' 
  | 'ada'
  | 'markdown'
  | 'latex';

export type ExecutionStatus = 
  | 'idle' 
  | 'queued' 
  | 'running' 
  | 'success' 
  | 'error' 
  | 'timeout' 
  | 'cancelled';

export type SealStatus = 
  | 'pending' 
  | 'sealed' 
  | 'verified' 
  | 'revoked';

export interface CellMetadata {
  createdAt: number;
  createdBy: string;
  modifiedAt: number;
  executedAt?: number;
  executedBy?: string;
  executionCount: number;
}

export interface CellOutput {
  type: 'text' | 'table' | 'graph' | 'math' | 'error' | 'html';
  data: string | Record<string, any>;
  mimeType?: string;
  hash: string;
  receiptId?: string;
}

export interface Cell {
  id: string;
  type: CellType;
  language: Language;
  source: string;
  output: CellOutput | null;
  executionTime?: number; // ms
  executionStatus: ExecutionStatus;
  dependsOn: string[]; // cell IDs
  metadata: CellMetadata;
  sealStatus: SealStatus;
  tags: string[];
}

export interface CellDependency {
  from: string; // source cell ID
  to: string;   // target cell ID
  type: 'data' | 'code' | 'config';
}

export interface NotebookMetadata {
  id: string;
  title: string;
  description: string;
  createdAt: number;
  modifiedAt: number;
  author: string;
  trustLevel: 'low' | 'medium' | 'high' | 'sovereign';
  version: string;
  tags: string[];
}

export interface Notebook {
  metadata: NotebookMetadata;
  cells: Cell[];
  variables: Map<string, any>;
  kernelVersion: string;
}
```

### File: `src/types/receipt.ts`

```typescript
export interface ReceiptRecord {
  id: string;
  eventId: string;
  cellId: string;
  timestamp: number;
  isoTimestamp: string;
  
  // Execution details
  command: string;
  allowlist: string;
  exitCode: number | null;
  
  // Cryptographic
  outputHash: string;
  outputLength: number;
  blake3Hash: string;
  ed25519Signature: string;
  previousHash: string | null;
  chainHash: string;
  
  // Verification
  verificationStatus: 'pending' | 'authorized' | 'provisional' | 'denied';
  verifiedBy?: string;
  verifiedAt?: number;
  
  // Agent info
  agent: 'sentinel' | 'oracle' | 'builder' | 'archivist' | 'berserker';
  trustLevel: 'low' | 'medium' | 'high' | 'sovereign';
}

export interface WormChainVerification {
  valid: boolean;
  errors: string[];
  lastVerifiedAt: number;
  integrityScore: number; // 0-100
}
```

### File: `src/types/execution.ts`

```typescript
export interface ExecutionRequest {
  cellId: string;
  source: string;
  language: string;
  dependencies: string[];
  executorAgent: 'builder' | 'oracle' | 'sentinel';
  timeout?: number; // milliseconds
  metadata?: Record<string, any>;
}

export interface ExecutionResponse {
  cellId: string;
  status: 'running' | 'success' | 'error' | 'timeout';
  output: {
    type: string;
    data: string;
  };
  executionTime: number;
  receiptId: string;
  wormHash: string;
  error?: {
    code: string;
    message: string;
    traceback?: string;
  };
}

export interface ExecutionTask {
  id: string;
  cellId: string;
  status: 'queued' | 'running' | 'completed' | 'failed';
  startedAt?: number;
  completedAt?: number;
  error?: string;
}
```

---

## PART 3: REACTIVE STATE MANAGEMENT

### File: `src/stores/notebook.store.ts`

```typescript
import type { Cell, Notebook, CellDependency, ReceiptRecord } from '../types/cell';
import type { NotebookMetadata } from '../types/cell';

type EventType = 
  | 'cell:created' 
  | 'cell:updated' 
  | 'cell:deleted' 
  | 'cell:executing' 
  | 'cell:executed'
  | 'receipt:sealed'
  | 'graph:updated'
  | 'notebook:saved';

type Callback = (data?: any) => void;

export class NotebookStore {
  private cells: Map<string, Cell> = new Map();
  private receipts: ReceiptRecord[] = [];
  private listeners: Map<EventType, Set<Callback>> = new Map();
  private metadata: NotebookMetadata;
  private isDirty = false;

  constructor(initialMetadata: NotebookMetadata) {
    this.metadata = initialMetadata;
  }

  // ========== Subscriptions ==========

  subscribe(event: EventType, callback: Callback): () => void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);

    // Return unsubscribe function
    return () => {
      this.listeners.get(event)!.delete(callback);
    };
  }

  private emit(event: EventType, data?: any) {
    this.listeners.get(event)?.forEach(cb => {
      try {
        cb(data);
      } catch (e) {
        console.error(`Error in listener for ${event}:`, e);
      }
    });
  }

  // ========== Cell Operations ==========

  addCell(cell: Cell): void {
    this.cells.set(cell.id, cell);
    this.isDirty = true;
    this.emit('cell:created', cell);
  }

  updateCell(cellId: string, updates: Partial<Cell>): void {
    const cell = this.cells.get(cellId);
    if (!cell) throw new Error(`Cell ${cellId} not found`);

    Object.assign(cell, updates);
    this.isDirty = true;
    this.emit('cell:updated', { cellId, updates });
  }

  deleteCell(cellId: string): void {
    if (!this.cells.has(cellId)) {
      throw new Error(`Cell ${cellId} not found`);
    }

    this.cells.delete(cellId);
    this.isDirty = true;
    
    // Remove dependencies
    this.cells.forEach((cell) => {
      cell.dependsOn = cell.dependsOn.filter(id => id !== cellId);
    });

    this.emit('cell:deleted', { cellId });
  }

  getCell(cellId: string): Cell | undefined {
    return this.cells.get(cellId);
  }

  getAllCells(): Cell[] {
    return Array.from(this.cells.values());
  }

  // ========== Cell Dependencies ==========

  getCellDependencies(cellId: string): string[] {
    return this.cells.get(cellId)?.dependsOn || [];
  }

  getDependencyGraph(): CellDependency[] {
    const graph: CellDependency[] = [];
    this.cells.forEach((cell) => {
      cell.dependsOn.forEach((depId) => {
        graph.push({ from: depId, to: cell.id, type: 'data' });
      });
    });
    return graph;
  }

  getExecutionOrder(): string[] {
    // Topological sort of dependency DAG
    const visited = new Set<string>();
    const order: string[] = [];

    const visit = (id: string, stack: Set<string> = new Set()) => {
      if (visited.has(id)) return;
      if (stack.has(id)) {
        throw new Error(`Circular dependency detected at cell ${id}`);
      }

      stack.add(id);
      const cell = this.cells.get(id);
      cell?.dependsOn.forEach(depId => visit(depId, stack));
      stack.delete(id);

      visited.add(id);
      order.push(id);
    };

    this.cells.forEach((_, id) => {
      try {
        visit(id);
      } catch (e) {
        console.error('Dependency resolution error:', e);
      }
    });

    return order;
  }

  // ========== Execution State ==========

  setExecuting(cellId: string): void {
    const cell = this.cells.get(cellId);
    if (cell) {
      cell.executionStatus = 'running';
      this.emit('cell:executing', { cellId });
    }
  }

  completeExecution(
    cellId: string,
    status: 'success' | 'error',
    output: any,
    executionTime: number
  ): void {
    const cell = this.cells.get(cellId);
    if (!cell) return;

    cell.executionStatus = status === 'success' ? 'success' : 'error';
    cell.output = output;
    cell.executionTime = executionTime;
    cell.metadata.executedAt = Date.now();
    cell.metadata.executionCount++;

    this.isDirty = true;
    this.emit('cell:executed', { cellId, status, output });
  }

  // ========== Receipt Management ==========

  addReceipt(receipt: ReceiptRecord): void {
    this.receipts.push(receipt);
    this.isDirty = true;
    this.emit('receipt:sealed', receipt);
  }

  getReceipts(): ReceiptRecord[] {
    return [...this.receipts];
  }

  getReceiptsByCell(cellId: string): ReceiptRecord[] {
    return this.receipts.filter(r => r.cellId === cellId);
  }

  // ========== Metadata ==========

  getMetadata(): NotebookMetadata {
    return { ...this.metadata };
  }

  updateMetadata(updates: Partial<NotebookMetadata>): void {
    this.metadata = { ...this.metadata, ...updates };
    this.isDirty = true;
  }

  // ========== Persistence ==========

  isDirtyCheck(): boolean {
    return this.isDirty;
  }

  markSaved(): void {
    this.isDirty = false;
    this.metadata.modifiedAt = Date.now();
    this.emit('notebook:saved', this.metadata);
  }

  // ========== Export ==========

  toJSON(): Notebook {
    return {
      metadata: this.metadata,
      cells: this.getAllCells(),
      variables: new Map(),
      kernelVersion: '1.0.0',
    };
  }

  static fromJSON(json: Notebook): NotebookStore {
    const store = new NotebookStore(json.metadata);
    json.cells.forEach(cell => store.addCell(cell));
    return store;
  }
}

// Global singleton
export const notebook = new NotebookStore({
  id: crypto.randomUUID(),
  title: 'Untitled Notebook',
  description: '',
  createdAt: Date.now(),
  modifiedAt: Date.now(),
  author: 'Unknown',
  trustLevel: 'medium',
  version: '1.0.0',
  tags: [],
});
```

---

## PART 4: WEB COMPONENTS

### File: `src/components/notebook-container.ts`

```typescript
import type { Cell } from '../types/cell';
import { notebook } from '../stores/notebook.store';

export class NotebookContainer extends HTMLElement {
  private container: HTMLDivElement | null = null;
  private unsubscribers: (() => void)[] = [];

  connectedCallback() {
    this.render();
    this.attachSubscriptions();
  }

  disconnectedCallback() {
    this.unsubscribers.forEach(fn => fn());
  }

  private attachSubscriptions() {
    this.unsubscribers.push(
      notebook.subscribe('cell:created', () => this.renderCells()),
      notebook.subscribe('cell:deleted', () => this.renderCells()),
      notebook.subscribe('receipt:sealed', () => this.updateLedger())
    );
  }

  private render() {
    this.innerHTML = `
      <div class="notebook-layout">
        <div class="notebook-header">
          <h1 class="notebook-title">${notebook.getMetadata().title}</h1>
          <div class="header-controls">
            <button class="btn-run" aria-label="Run all cells">▶ Run All</button>
            <button class="btn-save" aria-label="Save notebook">💾 Save</button>
            <button class="btn-export" aria-label="Export">⬇ Export</button>
          </div>
        </div>

        <div class="notebook-content">
          <aside class="sidebar-left">
            <div class="sidebar-section">
              <h3>Notebook Info</h3>
              <dl>
                <dt>Cells</dt>
                <dd id="cell-count">${notebook.getAllCells().length}</dd>
                <dt>Modified</dt>
                <dd id="modified-time">just now</dd>
              </dl>
            </div>
            <div class="sidebar-section">
              <h3>Dependency Graph</h3>
              <canvas id="graph-mini" width="200" height="200"></canvas>
            </div>
            <div class="sidebar-section">
              <h3>Trust Policies</h3>
              <select id="executor-agent">
                <option value="builder">Execute as builder</option>
                <option value="oracle">Execute as oracle</option>
              </select>
            </div>
          </aside>

          <main class="editor-area">
            <div class="execution-trace">
              <canvas id="trace-canvas" width="1400" height="60"></canvas>
            </div>
            <div id="cells-container" class="cells-container"></div>
          </main>

          <aside class="sidebar-right">
            <div class="worm-ledger">
              <h3>WORM Ledger</h3>
              <div id="receipt-list" class="receipt-list"></div>
            </div>
          </aside>
        </div>
      </div>
    `;

    this.container = this.querySelector('.notebook-content') as HTMLDivElement;
    this.attachEventListeners();
    this.renderCells();
    this.updateLedger();
  }

  private renderCells() {
    if (!this.container) return;

    const cellsContainer = this.querySelector('#cells-container') as HTMLDivElement;
    const cells = notebook.getAllCells();

    cellsContainer.innerHTML = cells
      .map(cell => `<notebook-cell cell-id="${cell.id}"></notebook-cell>`)
      .join('');

    // Initialize child components
    cells.forEach(cell => {
      const component = cellsContainer.querySelector(`notebook-cell[cell-id="${cell.id}"]`);
      if (component instanceof NotebookCell) {
        component.setState(cell);
      }
    });
  }

  private updateLedger() {
    const receiptList = this.querySelector('#receipt-list') as HTMLDivElement;
    const receipts = notebook.getReceipts();

    receiptList.innerHTML = receipts
      .slice(-10) // Show last 10
      .reverse()
      .map(receipt => `
        <div class="receipt-item" data-receipt-id="${receipt.id}">
          <div class="receipt-header">
            <code class="receipt-id">${receipt.id.slice(0, 12)}…</code>
            <span class="receipt-status ${receipt.verificationStatus}">
              ${receipt.verificationStatus}
            </span>
          </div>
          <div class="receipt-meta">
            <span>Cell: ${receipt.cellId}</span>
            <span>Time: ${new Date(receipt.timestamp).toLocaleTimeString()}</span>
          </div>
        </div>
      `)
      .join('');
  }

  private attachEventListeners() {
    this.querySelector('.btn-run')?.addEventListener('click', () => {
      this.runAllCells();
    });

    this.querySelector('.btn-save')?.addEventListener('click', () => {
      this.saveNotebook();
    });
  }

  private async runAllCells() {
    const order = notebook.getExecutionOrder();
    for (const cellId of order) {
      const cell = notebook.getCell(cellId);
      if (cell) {
        await this.executeCell(cellId);
      }
    }
  }

  private async executeCell(cellId: string) {
    // Implement execution logic
    notebook.setExecuting(cellId);
    // ... call runtime
  }

  private saveNotebook() {
    // Implement save logic
    notebook.markSaved();
    console.log('Notebook saved');
  }
}

export class NotebookCell extends HTMLElement {
  private cellState: Cell | null = null;

  connectedCallback() {
    this.render();
  }

  setState(cell: Cell) {
    this.cellState = cell;
    this.render();
  }

  private render() {
    if (!this.cellState) return;

    const cell = this.cellState;
    this.innerHTML = `
      <div class="cell" data-cell-id="${cell.id}">
        <div class="cell-header">
          <span class="cell-label">
            ${cell.type === 'code' ? '⚡' : '📝'} ${cell.id.slice(0, 8)}
          </span>
          <span class="cell-status ${cell.executionStatus}">
            ${cell.executionStatus}
          </span>
        </div>
        <cell-editor cell-id="${cell.id}"></cell-editor>
        ${cell.output ? `<cell-output cell-id="${cell.id}"></cell-output>` : ''}
        <div class="cell-footer">
          <button class="btn-run" aria-label="Run this cell">▶ Run</button>
          <button class="btn-delete" aria-label="Delete cell">🗑</button>
        </div>
      </div>
    `;

    this.addEventListener('click', (e) => {
      const target = e.target as HTMLElement;
      if (target.classList.contains('btn-run')) {
        this.dispatchEvent(new CustomEvent('cell:execute', {
          detail: { cellId: cell.id },
          bubbles: true,
        }));
      } else if (target.classList.contains('btn-delete')) {
        notebook.deleteCell(cell.id);
      }
    });
  }
}

customElements.define('notebook-container', NotebookContainer);
customElements.define('notebook-cell', NotebookCell);
```

### File: `src/components/cell-editor.ts`

```typescript
import hljs from 'highlight.js';
import type { Language } from '../types/cell';

export class CellEditor extends HTMLElement {
  private textarea: HTMLTextAreaElement | null = null;
  private highlighter: HTMLDivElement | null = null;
  private language: Language = 'python';

  connectedCallback() {
    this.language = (this.getAttribute('language') as Language) || 'python';
    this.render();
    this.setupSyntaxHighlighting();
  }

  private render() {
    this.innerHTML = `
      <div class="editor-wrapper">
        <div class="line-numbers" id="line-numbers"></div>
        <textarea 
          class="editor-textarea"
          spellcheck="false"
          placeholder="Enter code here..."
        ></textarea>
        <div class="highlights" id="highlights"></div>
      </div>
    `;

    this.textarea = this.querySelector('textarea') as HTMLTextAreaElement;
    this.highlighter = this.querySelector('#highlights') as HTMLDivElement;

    this.textarea.addEventListener('input', () => this.updateHighlights());
    this.textarea.addEventListener('scroll', () => this.syncScroll());
    this.textarea.addEventListener('keydown', (e) => this.handleKeydown(e));
  }

  private setupSyntaxHighlighting() {
    this.updateHighlights();
  }

  private updateHighlights() {
    if (!this.textarea || !this.highlighter) return;

    const code = this.textarea.value;
    const highlighted = hljs.highlight(code, { language: this.language, ignoreIllegals: true }).value;

    this.highlighter.innerHTML = `<pre><code>${highlighted}</code></pre>`;
    this.updateLineNumbers();
  }

  private updateLineNumbers() {
    if (!this.textarea) return;

    const lines = this.textarea.value.split('\n').length;
    const lineNumbers = this.querySelector('#line-numbers') as HTMLDivElement;

    if (lineNumbers) {
      lineNumbers.innerHTML = Array.from({ length: lines }, (_, i) =>
        `<div class="line-number">${i + 1}</div>`
      ).join('');
    }
  }

  private syncScroll() {
    if (!this.textarea || !this.highlighter) return;
    this.highlighter.scrollTop = this.textarea.scrollTop;
    this.highlighter.scrollLeft = this.textarea.scrollLeft;
  }

  private handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Tab') {
      e.preventDefault();
      const start = this.textarea!.selectionStart;
      const end = this.textarea!.selectionEnd;
      this.textarea!.value =
        this.textarea!.value.substring(0, start) +
        '\t' +
        this.textarea!.value.substring(end);
      this.textarea!.selectionStart = this.textarea!.selectionEnd = start + 1;
      this.updateHighlights();
    }
  }

  getCode(): string {
    return this.textarea?.value || '';
  }

  setCode(code: string) {
    if (this.textarea) {
      this.textarea.value = code;
      this.updateHighlights();
    }
  }
}

customElements.define('cell-editor', CellEditor);
```

### File: `src/components/cell-output.ts`

```typescript
import type { CellOutput } from '../types/cell';

export class CellOutputComponent extends HTMLElement {
  private output: CellOutput | null = null;

  connectedCallback() {
    // Load initial output from store
    const cellId = this.getAttribute('cell-id');
    if (cellId) {
      // TODO: Subscribe to updates
    }
  }

  setOutput(output: CellOutput) {
    this.output = output;
    this.render();
  }

  private render() {
    if (!this.output) {
      this.innerHTML = '';
      return;
    }

    this.innerHTML = `
      <div class="cell-output">
        <div class="output-header">
          <span class="output-type">${this.output.type}</span>
          <span class="output-hash" title="${this.output.hash}">
            ${this.output.hash.slice(0, 12)}…
          </span>
        </div>
        <div class="output-content">
          ${this.renderContent()}
        </div>
      </div>
    `;
  }

  private renderContent(): string {
    if (!this.output) return '';

    switch (this.output.type) {
      case 'text':
        return `<pre>${this.escapeHtml(String(this.output.data))}</pre>`;
      case 'error':
        return `<pre class="error">${this.escapeHtml(String(this.output.data))}</pre>`;
      case 'table':
        return this.renderTable();
      case 'html':
        return String(this.output.data);
      case 'math':
        return `<div class="math">${this.output.data}</div>`;
      default:
        return `<pre>${JSON.stringify(this.output.data, null, 2)}</pre>`;
    }
  }

  private renderTable(): string {
    if (!Array.isArray(this.output?.data)) return '';

    const data = this.output.data as Record<string, any>[];
    if (data.length === 0) return '<table></table>';

    const headers = Object.keys(data[0]);
    return `
      <table class="output-table">
        <thead>
          <tr>
            ${headers.map(h => `<th>${h}</th>`).join('')}
          </tr>
        </thead>
        <tbody>
          ${data.map(row => `
            <tr>
              ${headers.map(h => `<td>${this.escapeHtml(String(row[h]))}</td>`).join('')}
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  private escapeHtml(text: string): string {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

customElements.define('cell-output', CellOutputComponent);
```

---

## PART 5: ANIMATION ENGINE

### File: `src/animation/execution-flow.ts`

```typescript
interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  glyph: string;
  age: number;
  lifetime: number;
  opacity: number;
}

interface Arrow {
  fromX: number;
  fromY: number;
  toX: number;
  toY: number;
  progress: number;
  duration: number;
  startTime: number;
}

export class ExecutionFlowAnimator {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private particles: Particle[] = [];
  private arrows: Arrow[] = [];
  private animationId: number | null = null;
  private glyphs = ['λ', 'Ω', '∑', '⊕', 'φ', '∞', '↔', '⇄'];

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d')!;
  }

  startExecution(fromX: number, fromY: number, toX: number, toY: number, duration: number) {
    const arrow: Arrow = {
      fromX, fromY, toX, toY,
      progress: 0,
      duration,
      startTime: Date.now(),
    };
    this.arrows.push(arrow);

    // Spawn particles
    for (let i = 0; i < 3; i++) {
      setTimeout(() => {
        this.spawnParticle(fromX, fromY, toX, toY, duration);
      }, i * 200);
    }

    this.animate();
  }

  private spawnParticle(fromX: number, fromY: number, toX: number, toY: number, duration: number) {
    const glyph = this.glyphs[Math.floor(Math.random() * this.glyphs.length)];
    const distance = Math.sqrt((toX - fromX) ** 2 + (toY - fromY) ** 2);
    const speed = distance / duration;

    const dx = (toX - fromX) / distance;
    const dy = (toY - fromY) / distance;

    this.particles.push({
      x: fromX,
      y: fromY,
      vx: dx * speed,
      vy: dy * speed,
      glyph,
      age: 0,
      lifetime: duration,
      opacity: 1,
    });
  }

  private animate() {
    const now = Date.now();
    const dt = 1 / 60; // assume 60fps

    // Update particles
    this.particles.forEach(p => {
      p.age += dt;
      p.x += p.vx * dt * 1000;
      p.y += p.vy * dt * 1000;
      p.opacity = Math.max(0, 1 - p.age / p.lifetime);
    });

    // Remove expired particles
    this.particles = this.particles.filter(p => p.age < p.lifetime);

    // Update arrows
    this.arrows.forEach(a => {
      a.progress = (now - a.startTime) / a.duration;
    });

    // Remove completed arrows
    this.arrows = this.arrows.filter(a => a.progress < 1);

    // Render
    this.render();

    if (this.particles.length > 0 || this.arrows.length > 0) {
      this.animationId = requestAnimationFrame(() => this.animate());
    }
  }

  private render() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    // Draw arrows
    this.arrows.forEach(arrow => {
      const x = arrow.fromX + (arrow.toX - arrow.fromX) * arrow.progress;
      const y = arrow.fromY + (arrow.toY - arrow.fromY) * arrow.progress;

      // Draw line
      this.ctx.strokeStyle = `rgba(126, 249, 255, ${0.6 * (1 - arrow.progress)})`;
      this.ctx.lineWidth = 2;
      this.ctx.beginPath();
      this.ctx.moveTo(arrow.fromX, arrow.fromY);
      this.ctx.lineTo(x, y);
      this.ctx.stroke();

      // Draw arrowhead
      this.drawArrowhead(x, y, arrow.fromX, arrow.fromY);
    });

    // Draw particles
    this.particles.forEach(p => {
      this.ctx.font = '24px Arial';
      this.ctx.fillStyle = `rgba(255, 121, 220, ${p.opacity})`;
      this.ctx.textAlign = 'center';
      this.ctx.textBaseline = 'middle';
      this.ctx.fillText(p.glyph, p.x, p.y);
    });
  }

  private drawArrowhead(toX: number, toY: number, fromX: number, fromY: number) {
    const angle = Math.atan2(toY - fromY, toX - fromX);
    const headlen = 12;

    this.ctx.strokeStyle = 'rgba(126, 249, 255, 0.8)';
    this.ctx.lineWidth = 2;
    this.ctx.beginPath();
    this.ctx.moveTo(toX - headlen * Math.cos(angle - Math.PI / 6), toY - headlen * Math.sin(angle - Math.PI / 6));
    this.ctx.lineTo(toX, toY);
    this.ctx.lineTo(toX - headlen * Math.cos(angle + Math.PI / 6), toY - headlen * Math.sin(angle + Math.PI / 6));
    this.ctx.stroke();
  }

  stop() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
  }
}
```

---

## PART 6: RUNTIME BRIDGE

### File: `src/services/runtime-bridge.ts`

```typescript
import type { ExecutionRequest, ExecutionResponse } from '../types/execution';
import type { ReceiptRecord } from '../types/receipt';
import { notebook } from '../stores/notebook.store';

export class RuntimeBridge {
  private baseUrl: string;
  private wsConnection: WebSocket | null = null;

  constructor(baseUrl: string = '/api') {
    this.baseUrl = baseUrl;
  }

  async executeCell(request: ExecutionRequest): Promise<ExecutionResponse> {
    notebook.setExecuting(request.cellId);

    try {
      const response = await fetch(`${this.baseUrl}/execute`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(request),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = (await response.json()) as ExecutionResponse;

      // Update notebook state
      notebook.completeExecution(
        request.cellId,
        data.status === 'success' ? 'success' : 'error',
        data.output,
        data.executionTime
      );

      // Add receipt
      const receipt: ReceiptRecord = {
        id: data.receiptId,
        eventId: request.cellId,
        cellId: request.cellId,
        timestamp: Date.now(),
        isoTimestamp: new Date().toISOString(),
        command: request.source,
        allowlist: '',
        exitCode: null,
        outputHash: '',
        outputLength: 0,
        blake3Hash: data.wormHash,
        ed25519Signature: '',
        previousHash: null,
        chainHash: '',
        verificationStatus: 'pending',
        agent: request.executorAgent,
        trustLevel: 'medium',
      };

      notebook.addReceipt(receipt);

      return data;
    } catch (error) {
      console.error('Execution failed:', error);
      notebook.completeExecution(
        request.cellId,
        'error',
        { type: 'error', data: String(error) },
        0
      );
      throw error;
    }
  }

  async verifyReceipt(receiptId: string): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/verify/${receiptId}`);
      return response.ok;
    } catch {
      return false;
    }
  }

  connectWebSocket(handler: (event: any) => void) {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const url = `${protocol}//${window.location.host}/api/ws`;

    this.wsConnection = new WebSocket(url);
    this.wsConnection.onmessage = (event) => {
      handler(JSON.parse(event.data));
    };

    return new Promise((resolve) => {
      this.wsConnection!.onopen = resolve;
    });
  }

  disconnect() {
    if (this.wsConnection) {
      this.wsConnection.close();
      this.wsConnection = null;
    }
  }
}

export const runtime = new RuntimeBridge();
```

---

## PART 7: STYLING SCAFFOLD

### File: `styles/global.css`

```css
/* Design Tokens */
:root {
  --color-bg-primary: #070b1e;
  --color-bg-secondary: #0f0f2e;
  --color-text-primary: #eef9ff;
  --color-text-secondary: #a0a7d0;
  --color-accent-cyan: #7ef9ff;
  --color-accent-magenta: #ff79dc;
  --color-accent-gold: #ffe98a;
  --color-error: #ff4fd8;
  --color-success: #00d9a3;
  --color-warning: #ffd86b;

  --font-mono: 'Fira Code', 'Courier New', monospace;
  --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  
  --shadow-md: 0 8px 24px rgba(0, 0, 0, 0.5);
  --transition-fast: 150ms ease-out;
}

/* Resets */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  background: var(--color-bg-primary);
  color: var(--color-text-primary);
  font-family: var(--font-sans);
  font-size: 16px;
  line-height: 1.6;
}

/* Layout */
.notebook-layout {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.notebook-content {
  display: grid;
  grid-template-columns: 200px 1fr 300px;
  flex: 1;
  gap: var(--spacing-md);
  overflow: hidden;
}

@media (max-width: 768px) {
  .notebook-content {
    grid-template-columns: 1fr;
  }
  
  .sidebar-left,
  .sidebar-right {
    display: none;
  }
}

/* Components */
button {
  background: var(--color-bg-secondary);
  color: var(--color-text-primary);
  border: 1px solid var(--color-accent-cyan);
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: 4px;
  cursor: pointer;
  font-family: inherit;
  transition: all var(--transition-fast);
}

button:hover {
  background: var(--color-accent-cyan);
  color: var(--color-bg-primary);
}

code {
  font-family: var(--font-mono);
  font-size: 0.9em;
  padding: 2px 6px;
  background: var(--color-bg-secondary);
  border-radius: 3px;
}
```

---

## PART 8: ENTRY POINT

### File: `src/index.ts`

```typescript
import { NotebookContainer } from './components/notebook-container';
import './styles/global.css';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('app');
  if (root) {
    const app = document.createElement('notebook-container');
    root.appendChild(app);
  }
});
```

### File: `index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sovereign Notebook</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css">
</head>
<body>
  <div id="app"></div>
  <script type="module" src="/src/index.ts"></script>
</body>
</html>
```

---

## PART 9: DEVELOPMENT WORKFLOW

### Build & Run

```bash
# Install dependencies
npm install

# Development server with hot reload
npm run dev

# Build for production
npm build

# Run tests
npm test

# Run tests with UI
npm run test:ui

# Format code
npx prettier --write src/
```

### Key Development Commands

```bash
# Quick component prototype
touch src/components/my-component.ts

# Run single test file
npm test src/components/__tests__/my-component.test.ts

# Generate types from notebook JSON
npx ts-node scripts/generate-types.ts
```

---

## NEXT STEPS

1. **Setup**: Follow Part 1 project initialization
2. **Types**: Define all interfaces (Part 2)
3. **State**: Implement NotebookStore (Part 3)
4. **Components**: Build Web Components (Part 4)
5. **Animation**: Add canvas animations (Part 5)
6. **Integration**: Wire runtime bridge (Part 6)
7. **Styling**: Implement CSS architecture (Part 7)
8. **Testing**: Add unit & integration tests
9. **Deploy**: Build and deploy to production

---

**Document Finalized**: 2026-07-27 14:45 UTC  
**Ready for Development**: ✓
