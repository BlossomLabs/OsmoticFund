import { defineConfig } from "tsup";

export default defineConfig({
  bundle: true,
  clean: true,
  dts: true,
  sourcemap: true,
  format: ["esm"],
  silent: true,
  splitting: true,
  target: "es2021",
  entry: ["src/index.ts"],
});
