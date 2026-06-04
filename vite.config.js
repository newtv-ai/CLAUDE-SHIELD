import { defineConfig } from "vite";
import { sveltekit } from "@sveltejs/kit/vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [sveltekit()],
  server: {
    host: "127.0.0.1",
    port: 5173
  }
});
