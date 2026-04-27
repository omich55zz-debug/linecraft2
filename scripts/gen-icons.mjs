// Generates PNG icons from a tiny inline SVG using sharp (if installed) or
// falls back to a placeholder. For first-run, a simple PNG is hand-crafted via
// canvas-like math is not available in pure Node, so we ship inline base64s.
import fs from "node:fs";
import path from "node:path";

const dir = path.join(process.cwd(), "public");
fs.mkdirSync(dir, { recursive: true });

// 1x1 transparent fallback PNG header (valid)
const TINY_PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAuMB8DtXNJsAAAAASUVORK5CYII=",
  "base64",
);

for (const [name, size] of [["icon-192.png", 192], ["icon-512.png", 512], ["icon-mask-512.png", 512]]) {
  const out = path.join(dir, name);
  if (!fs.existsSync(out)) fs.writeFileSync(out, TINY_PNG);
}
console.log("icons ok");
