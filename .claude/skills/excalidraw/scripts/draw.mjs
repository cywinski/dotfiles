// ABOUTME: CLI that turns a mermaid definition or an Excalidraw element skeleton into a
// real .excalidraw scene plus rendered .svg / .png, using headless Chrome for true layout.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };

/** Parse `--flag value` / `--flag` argv into a plain object. */
function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith("--")) throw new Error(`unexpected argument: ${argv[i]}`);
    const key = argv[i].slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith("--")) args[key] = true;
    else { args[key] = next; i++; }
  }
  return args;
}

/** Read a file path, or stdin when the path is "-". */
function readInput(source) {
  if (source === "-") return fs.readFileSync(0, "utf8");
  if (!fs.existsSync(source)) throw new Error(`input file not found: ${source}`);
  return fs.readFileSync(source, "utf8");
}

/** Serve the skill's scripts/ directory so the bundle can load as a normal web page. */
async function startServer() {
  const server = http.createServer((req, res) => {
    const file = path.join(HERE, decodeURIComponent(req.url.split("?")[0]));
    if (!file.startsWith(HERE) || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { "content-type": MIME[path.extname(file)] ?? "application/octet-stream" });
    fs.createReadStream(file).pipe(res);
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  return { server, port: server.address().port };
}

/** Local-time stamp used in every output filename, e.g. 20260911-154233. */
function timestamp() {
  const now = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  return `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}`
    + `-${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

const args = parseArgs(process.argv.slice(2));
if (!args.mermaid && !args.skeleton) {
  console.error(`usage: node draw.mjs (--mermaid <file|-> | --skeleton <file|->) --out-dir <dir> --name <slug>
                 [--dark] [--scale <n>] [--bg <css-color>] [--theme <excalidraw theme json>]`);
  process.exit(2);
}
if (args.mermaid && args.skeleton) throw new Error("pass either --mermaid or --skeleton, not both");

const bundle = path.join(HERE, "bundle.js");
if (!fs.existsSync(bundle)) {
  throw new Error(`missing ${bundle} — run scripts/setup.sh in the skill directory first`);
}

const outDir = args["out-dir"] ?? "output/diagrams";
const name = args.name ?? "diagram";
const scale = Number(args.scale ?? 2);
const dark = args.dark === true;
const background = args.bg ?? (dark ? "#121212" : "#ffffff");

const source = readInput(args.mermaid ?? args.skeleton);
const mode = args.mermaid ? "mermaid" : "skeleton";

const { server, port } = await startServer();
const browser = await chromium.launch({ channel: "chrome" });
const page = await browser.newPage();
const pageErrors = [];
page.on("pageerror", (error) => pageErrors.push(error.message));
await page.goto(`http://127.0.0.1:${port}/page.html`);
await page.waitForFunction(() => window.EXC !== undefined, null, { timeout: 60000 });

const result = await page.evaluate(async ({ source, mode, dark, background, scale }) => {
  // Excalidraw fits bound text inside a diamond's inscribed rectangle (~half the
  // container), but mermaid sizes diamonds for its own tighter label box. Without
  // this, diamond labels wrap mid-word. Grow the diamond around its centre instead.
  const fitDiamondLabels = (elements) => {
    const canvas = document.createElement("canvas").getContext("2d");
    for (const element of elements) {
      if (element.type !== "diamond" || !element.label?.text) continue;
      const fontSize = element.label.fontSize ?? 20;
      canvas.font = `${fontSize}px Excalifont, sans-serif`;
      const lines = String(element.label.text).split("\n");
      const textWidth = Math.max(...lines.map((line) => canvas.measureText(line).width));
      const needWidth = 2 * textWidth + 60;
      const needHeight = 2 * lines.length * fontSize * 1.25 + 40;
      if (needWidth > element.width) {
        element.x -= (needWidth - element.width) / 2;
        element.width = needWidth;
      }
      if (needHeight > element.height) {
        element.y -= (needHeight - element.height) / 2;
        element.height = needHeight;
      }
    }
    return elements;
  };

  let skeleton;
  if (mode === "mermaid") {
    const parsed = await window.EXC.parseMermaidToExcalidraw(source);
    // mermaid-to-excalidraw only converts flowchart/sequence natively; every other
    // diagram type silently degrades to one embedded raster image. That is not an
    // editable scene, so refuse it instead of writing a file that cannot be edited.
    if (parsed.elements.some((element) => element.type === "image")) {
      return { unsupported: true };
    }
    skeleton = fitDiamondLabels(parsed.elements);
  } else {
    skeleton = JSON.parse(source);
    if (!Array.isArray(skeleton)) throw new Error("skeleton input must be a JSON array of elements");
  }

  await document.fonts.ready;
  const elements = window.EXC.convertToExcalidrawElements(skeleton);
  const appState = {
    exportBackground: true,
    viewBackgroundColor: background,
    exportPadding: 24,
    exportWithDarkMode: dark,
  };
  const svg = await window.EXC.exportToSvg({ elements, appState, files: null });
  const blob = await window.EXC.exportToBlob({
    elements, appState, files: null, mimeType: "image/png", quality: 1, exportScale: scale,
  });
  const bytes = new Uint8Array(await blob.arrayBuffer());
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return {
    elements,
    svg: new XMLSerializer().serializeToString(svg),
    png: btoa(binary),
    width: Number(svg.getAttribute("width")),
    height: Number(svg.getAttribute("height")),
  };
}, { source, mode, dark, background, scale });

await browser.close();
server.close();

if (pageErrors.length > 0) throw new Error(`browser errors: ${pageErrors.join(" | ")}`);
if (result.unsupported) {
  throw new Error(
    "mermaid-to-excalidraw cannot convert this diagram type into editable shapes "
    + "(only flowchart/graph and sequenceDiagram are supported; class, state, ER, gantt and "
    + "mindmap degrade to a flat image). Rebuild this diagram with --skeleton instead.",
  );
}

fs.mkdirSync(outDir, { recursive: true });
const stem = path.join(outDir, `${timestamp()}-${name}`);
const scene = {
  type: "excalidraw",
  version: 2,
  source: "https://excalidraw.com",
  elements: result.elements,
  appState: { viewBackgroundColor: background, gridSize: null },
  files: {},
};
fs.writeFileSync(`${stem}.excalidraw`, JSON.stringify(scene, null, 2));
fs.writeFileSync(`${stem}.svg`, result.svg);
fs.writeFileSync(`${stem}.png`, Buffer.from(result.png, "base64"));

console.log(JSON.stringify({
  excalidraw: `${stem}.excalidraw`,
  svg: `${stem}.svg`,
  png: `${stem}.png`,
  elements: result.elements.length,
  size: [result.width, result.height],
}, null, 2));
