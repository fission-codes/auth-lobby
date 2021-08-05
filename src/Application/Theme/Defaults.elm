module Theme.Defaults exposing (..)

import Color
import Kit
import Theme exposing (Theme)



-- colors : Theme.Colors
-- colors =
--     { darkScheme =
--         { accent = Color.toCssString Kit.colors.gray_200
--         , tag = Just (Color.toCssString Kit.colors.purple)
--         }
--     , lightScheme =
--         { accent = Color.toCssString Kit.colors.purple_shade
--         , tag = Nothing
--         }
--     }


empty : Theme
empty =
    { introduction = Nothing
    , logo = Nothing
    }


introduction : String
introduction =
    """
    It doesn't look like you've signed in on this device before.

    If you don't know what Fission is, learn more on [our website](https://fission.codes).
    """
        |> String.lines
        |> List.map String.trim
        |> String.join "\n"


logo : Theme.Logo
logo =
    { darkScheme = "/images/logo-light.svg"
    , lightScheme = "/images/logo-dark.svg"
    , styles = Just "opacity: 0.9"
    }
