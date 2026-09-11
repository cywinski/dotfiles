---
name: excalidraw
description: Draw a diagram as a real, hand-editable Excalidraw scene (.excalidraw) plus rendered PNG/SVG. Use ONLY when explicitly asked to draw, sketch, diagram, or visualize something — "draw me a diagram", "sketch the architecture", "visualize this pipeline", "make an excalidraw of X" — or via /excalidraw. Do NOT use it unprompted while explaining things; prose and inline mermaid are the default. Good for architecture, data/training pipelines, experiment flows, attention/model internals sketches, state machines, before/after comparisons.
---

# Excalidraw diagrams

Produces three files from one command: an editable `.excalidraw` scene (open at
[excalidraw.com](https://excalidraw.com) via *Open* / drag-and-drop), plus a rendered `.png` and
`.svg`. Rendering runs the genuine Excalidraw engine in headless Chrome, so the output is exactly
what the scene looks like when opened — hand-drawn strokes, Excalifont, real text layout.

## When NOT to use this

- Explaining something in passing — write prose or a mermaid block instead.
- Plots of actual data — use the `plotting` skill.
- The user wants a polished figure for a paper — use `plotting` (TikZ/matplotlib), not a sketch.

## Setup (once per machine)

```bash
bash ~/.claude/skills/excalidraw/scripts/setup.sh
```

Installs build deps, bundles the browser payload, prunes back to runtime-only (~27 MB total).
Requires Google Chrome at `/Applications/Google Chrome.app` (used headlessly; it does not touch
the user's browser profile or session). Re-run only after changing `scripts/browser-entry.js`.

## Usage

Two input modes. **Try mermaid first** — it auto-lays-out and is far harder to get wrong. Drop to a
skeleton when you need specific placement, grouping, free annotation, or a diagram type mermaid
mode refuses.

> **Mermaid mode only supports `flowchart` / `graph` and `sequenceDiagram`.** Every other mermaid
> type (`classDiagram`, `stateDiagram`, ER, gantt, mindmap) degrades to a single flat raster image
> rather than editable shapes, so `draw.mjs` refuses it with an error and writes nothing. Build
> those with `--skeleton`.

```bash
# mermaid: flowchart / sequence / class diagrams, automatic layout
node ~/.claude/skills/excalidraw/scripts/draw.mjs --mermaid diagram.mmd \
  --out-dir output/diagrams --name router-flow

# skeleton: hand-placed shapes, full control
node ~/.claude/skills/excalidraw/scripts/draw.mjs --skeleton scene.json \
  --out-dir output/diagrams --name steering-loop
```

Both accept `-` to read from stdin. Flags: `--dark`, `--scale <n>` (PNG scale, default 2),
`--bg <css-color>`. Prints a JSON block with the three output paths. Takes ~2 s.

Default `--out-dir` is `output/diagrams` in the current project; files are named
`<YYYYMMDD-HHMMSS>-<name>.{excalidraw,svg,png}`.

## Skeleton format

A JSON array of Excalidraw *skeleton* elements — a compact form that
`convertToExcalidrawElements` expands into a full scene (ids, seeds, bindings, bound text).

```json
[
  {"type":"text","x":0,"y":-60,"text":"Title here","fontSize":28},
  {"type":"rectangle","id":"acts","x":0,"y":0,"width":220,"height":80,
   "backgroundColor":"#e7f5ff","fillStyle":"solid","label":{"text":"residual acts\nlayer 14"}},
  {"type":"diamond","id":"gate","x":320,"y":170,"width":220,"height":120,
   "backgroundColor":"#ffe3e3","fillStyle":"solid","label":{"text":"feature fires?"}},
  {"type":"arrow","x":230,"y":40,"width":80,"height":0,
   "start":{"id":"acts"},"end":{"id":"gate"},"label":{"text":"yes"},"strokeColor":"#2f9e44"}
]
```

- Shapes: `rectangle`, `ellipse`, `diamond`, `arrow`, `line`, `text`, `frame`.
- A state machine is just rounded boxes plus labelled arrows; a class diagram is a box per class
  with `\n`-separated members. Both are quick to hand-place.
- `label.text` binds text **inside** a shape and centres it; `\n` forces a line break.
- Arrows bind by `"start":{"id":...}` / `"end":{"id":...}` — the arrow then reroutes itself around
  the shapes, so its own `x/y/width/height` only need to be roughly right.
- Give shapes an explicit `id` only when an arrow references them.
- `fillStyle` must be set (`"solid"` / `"hachure"`) for `backgroundColor` to show.

A worked example lives in `examples/steering-loop.json`.

### Layout rules of thumb

- ~80 px height for a one-line box, ~110 px for two lines; 120–240 px gaps between boxes.
- Width ≈ 11 px per character at the default font size, plus 40 px padding.
- Diamonds need roughly **twice** the width of their label — the mermaid path handles this
  automatically, but size them generously by hand.
- Palette that reads well in both themes: blue `#e7f5ff`, yellow `#fff3bf`, red `#ffe3e3`,
  green `#d3f9d8`, grey `#f1f3f5`. Stroke accents: `#2f9e44` (good path), `#e03131` (bad path).

## Delivering the result

Per the user's global preferences, always **send the PNG** with `SendUserFile` (or the current
app's attachment mechanism) — never just print a path. Then mention the `.excalidraw` path in one
line so they know they can open and edit it. If the diagram is part of a report, reference the PNG
by relative path in the markdown too.

## Testing

```bash
node ~/.claude/skills/excalidraw/tests/roundtrip.mjs
```

Generates one diagram per input mode and re-imports each `.excalidraw` through Excalidraw's own
`loadFromBlob` — the same code path excalidraw.com uses — asserting the element count survives.

## How it works

`scripts/browser-entry.js` bundles `@excalidraw/mermaid-to-excalidraw` and `@excalidraw/excalidraw`
into `scripts/bundle.js`. `scripts/draw.mjs` serves that over a throwaway localhost server, drives
it with `playwright-core` + system Chrome, and writes the results. A real browser is required
because mermaid measures text with the DOM — under jsdom there is no layout engine, labels measure
wrong, and boxes come out cramped and overlapping.
