import * as kit from "fission-kit"
import animations from "tailwindcss-animations"
import defaultTheme from "tailwindcss/defaultTheme.js"


export default {

  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////

  theme: {

    // Animations
    // ----------

    animations: {
      "spin": {
        from: { transform: "rotate(0deg)" },
        to: { transform: "rotate(360deg)" },
      },
    },

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

      fontSize: {
        "tiny": "0.8125rem" // between `xs` and `sm`
      },

      screens: {
        dark: { raw: "(prefers-color-scheme: dark)" }
      },

    },

  },


  /////////////////////////////////////////
  // VARIANTS /////////////////////////////
  /////////////////////////////////////////

  variants: {
    margin: [ "responsive", "last" ]
  },


  /////////////////////////////////////////
  // PLUGINS //////////////////////////////
  /////////////////////////////////////////

  plugins: [

    animations,

  ]

}
