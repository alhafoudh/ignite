import react from "@vitejs/plugin-react";
import {defineConfig, UserConfigExport} from "vite";
import checker from "vite-plugin-checker";
import FullReload from "vite-plugin-full-reload";
import RubyPlugin from "vite-plugin-ruby";

export default defineConfig(({mode}) => {
  const cfg: UserConfigExport = {
    resolve: {
      alias: {
        // atom: resolve(__dirname, "app/javascript/components/atoms"),
        // lib: resolve(__dirname, "app/javascript/lib"),
        // molecule: resolve(__dirname, "app/javascript/components/molecules"),
        // organism: resolve(__dirname, "app/javascript/components/organisms"),
        // template: resolve(__dirname, "app/javascript/components/templates"),
        // "graphql/types": resolve(__dirname, "app/javascript/graphql/types.ts"),
      },
    },
    plugins: [
      RubyPlugin(),
      react(),
      checker({
        typescript: true,
        overlay: true,
      }),
      FullReload(["config/routes.rb", "app/views/**/*"], {delay: 250}),
    ],
  };

  if (mode === "production") {
    cfg.build = {
      rollupOptions: {
        external: ["/@vite-plugin-checker-runtime"],
      },
    };
  }

  return cfg;
});