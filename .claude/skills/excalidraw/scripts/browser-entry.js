// ABOUTME: Browser-side entry bundled by esbuild into scripts/bundle.js.
// Exposes the excalidraw conversion and export APIs on window for the Playwright driver.
import { parseMermaidToExcalidraw } from "@excalidraw/mermaid-to-excalidraw";
import { convertToExcalidrawElements, exportToSvg, exportToBlob, loadFromBlob } from "@excalidraw/excalidraw";

window.EXC = { parseMermaidToExcalidraw, convertToExcalidrawElements, exportToSvg, exportToBlob, loadFromBlob };
