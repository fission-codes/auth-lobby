import * as kit from "@fission-suite/kit"
import defaultTheme from "tailwindcss/defaultTheme.js"


export default {

  purge: {
    content: [ "dist/*.js" ],
    safelist: [
      "animate-loading-bugfix-placeholder-rotate",
      "animate-loading-bugfix-placeholder-line-1",
      "animate-loading-bugfix-placeholder-line-2",
      "animate-loading-bugfix-placeholder-line-3",
      "animate-loading-bugfix-placeholder-line-4",
    ]
  },


  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////

  theme: {

    // Colors
    // ------

    colors: {
      ...kit.dasherizeObjectKeys(kit.colors),

      "current-color": "currentColor",
      "inherit": "inherit",
      "transparent": "transparent"
    },

    // Fonts
    // -----

    fontFamily: kit.fonts,

    // Inset
    // -----

    inset: {
      "auto": "auto",
      "0": 0,
      "1/2": "50%",
      "full": "100%"
    },

    // Opacity
    // -------

    opacity: {
      "0": "0",
      "025": ".025",
      "05": ".05",
      "075": ".075",
      "10": ".1",
      "20": ".2",
      "25": ".25",
      "30": ".3",
      "40": ".4",
      "50": ".5",
      "60": ".6",
      "70": ".7",
      "75": ".75",
      "80": ".8",
      "90": ".9",
      "100": "1",
    },

    // Extensions
    // ==========

    extend: {
      keyframes: kit.keyframes,
      animation: kit.animations,
      fontSize: kit.fontSizes,

      screens: {
        dark: { raw: "(prefers-color-scheme: dark)" }
      },
    },

  },


  /////////////////////////////////////////
  // VARIANTS /////////////////////////////
  /////////////////////////////////////////

  variants: {
    borderColor: [ "first", "last", "responsive" ],
    borderRadius: [ "first", "last", "responsive" ],
    borderWidth: [ "first", "last", "responsive" ],
    margin: [ "first",  "last", "responsive" ],
    padding: [ "first",  "last", "responsive" ]
  },


  /////////////////////////////////////////
  // PLUGINS //////////////////////////////
  /////////////////////////////////////////

  plugins: []

}
