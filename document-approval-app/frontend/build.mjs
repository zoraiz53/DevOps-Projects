import { mkdir, cp, rm } from "node:fs/promises";
import { build } from "esbuild";

await rm("dist", { recursive: true, force: true });
await mkdir("dist/assets", { recursive: true });

await build({
  entryPoints: ["src/main.tsx"],
  bundle: true,
  outfile: "dist/assets/app.js",
  format: "iife",
  target: ["es2018"],
  loader: {
    ".ts": "ts",
    ".tsx": "tsx",
    ".css": "css",
  },
  define: {
    "process.env.NODE_ENV": '"production"',
  },
});

await cp("index.html", "dist/index.html");
await cp("nginx.conf", "dist/nginx.conf");
await cp("docker-entrypoint.sh", "dist/docker-entrypoint.sh");
