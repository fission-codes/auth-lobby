import * as kit from "fission-kit"
import defaultTheme from "tailwindcss/defaultTheme.js"


export default {

  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////

  theme: {

    // Colors
    // ------

    colors: {
      ...kit.dasherizeObjectKeys(kit.colors),

      "inherit": "inherit",
      "transparent": "transparent"
    },

    // Fonts
    // -----

    fontFamily: {
      ...defaultTheme.fontFamily,

      body: [ kit.fonts.body, ...defaultTheme.fontFamily.sans ],
      display: [ kit.fonts.display, ...defaultTheme.fontFamily.serif ],
      mono: [ kit.fonts.mono, ...defaultTheme.fontFamily.mono ],
    },

    // Extensions
    // ==========

    extend: {

      screens: {
        dark: { raw: '(prefers-color-scheme: dark)' }
      },

    },

  }

}
