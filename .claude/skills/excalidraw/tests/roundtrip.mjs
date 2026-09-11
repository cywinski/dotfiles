// ABOUTME: Verifies generated .excalidraw files load through Excalidraw's own importer
// (loadFromBlob — the same path excalidraw.com uses), so the deliverable is really openable.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPTS = path.join(HERE, "..", "scripts");
const TMP = fs.mkdtempSync("/tmp/excalidraw-skill-test-");

const MERMAID = `flowchart LR\n  A[input] --> B{check}\n  B -->|ok| C[done]\n  B -->|fail| D[retry]`;
const SKELETON = JSON.stringify([
  { type: "rectangle", id: "a", x: 0, y: 0, width: 180, height: 70, label: { text: "alpha" } },
  { type: "ellipse", id: "b", x: 280, y: 0, width: 180, height: 70, label: { text: "beta" } },
  { type: "arrow", x: 190, y: 35, width: 80, height: 0, start: { id: "a" }, end: { id: "b" }, label: { text: "flows" } },
]);

fs.writeFileSync(path.join(TMP, "in.mmd"), MERMAID);
fs.writeFileSync(path.join(TMP, "in.json"), SKELETON);

const run = (flag, file, name) => JSON.parse(execFileSync("node",
  [path.join(SCRIPTS, "draw.mjs"), flag, path.join(TMP, file), "--out-dir", TMP, "--name", name],
  { encoding: "utf8" }));

const cases = [run("--mermaid", "in.mmd", "mermaid"), run("--skeleton", "in.json", "skeleton")];

const server = http.createServer((req, res) => {
  const file = path.join(SCRIPTS, decodeURIComponent(req.url.split("?")[0]));
  if (!file.startsWith(SCRIPTS) || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { "content-type": path.extname(file) === ".html" ? "text/html" : "text/javascript" });
  fs.createReadStream(file).pipe(res);
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));

const browser = await chromium.launch({ channel: "chrome" });
const page = await browser.newPage();
await page.goto(`http://127.0.0.1:${server.address().port}/page.html`);
await page.waitForFunction(() => window.EXC !== undefined, null, { timeout: 60000 });

let failures = 0;
for (const result of cases) {
  const label = path.basename(result.excalidraw);
  for (const key of ["excalidraw", "svg", "png"]) {
    const bytes = fs.statSync(result[key]).size;
    if (bytes === 0) { console.error(`FAIL ${label}: ${key} is empty`); failures++; }
  }
  const imported = await page.evaluate(async (text) => {
    const scene = await window.EXC.loadFromBlob(new Blob([text], { type: "application/json" }), null, null);
    return { count: scene.elements.length, types: [...new Set(scene.elements.map((e) => e.type))] };
  }, fs.readFileSync(result.excalidraw, "utf8"));

  if (imported.count !== result.elements) {
    console.error(`FAIL ${label}: wrote ${result.elements} elements, importer read back ${imported.count}`);
    failures++;
  } else {
    console.log(`PASS ${label}: ${imported.count} elements reimported [${imported.types.join(", ")}]`);
  }
}

await browser.close();
server.close();
fs.rmSync(TMP, { recursive: true, force: true });
if (failures > 0) { console.error(`\n${failures} check(s) failed`); process.exit(1); }
console.log("\nall checks passed");
