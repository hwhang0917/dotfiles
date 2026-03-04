import path from "path";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";

export default defineConfig({
  root: path.resolve(__dirname),
  plugins: [react(), viteSingleFile()],
  build: {
    outDir: "dist",
  },
});
