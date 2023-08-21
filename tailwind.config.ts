import type {Config} from "tailwindcss";

export default {
  darkMode: "class",
  content: [
    "./app/helpers/**/*.rb",
    "./app/views/**/*.{html,html.erb,erb}",
    "./app/views/devise/**/*.{html,html.erb,erb}",
    "./app/admin/**/*.rb",
    "./app/assets/stylesheets/**/*.scss",
    "./app/assets/javascripts/**/*.js",
    "./app/javascript/components/**/*.{vue,js,ts,jsx,tsx}",
    "./app/javascript/**/*.{vue,js,ts,jsx,tsx}",
    "./app/**/*.{vue,js,ts,jsx,tsx}",
    "./config/locales/*.yml",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          // generate something nice here: https://uicolors.app/create
        },
      },
    },
  },
} satisfies Config;