module Markdown.Renderer.Custom exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Markdown.Renderer exposing (Renderer, defaultHtmlRenderer)
import Tailwind as T


default : Renderer (Html msg)
default =
    { defaultHtmlRenderer
      -- Link
        | link =
            \{ title, destination } ->
                Html.a
                    [ A.href destination
                    , A.title (Maybe.withDefault "" title)

                    --
                    , T.text_gray_100
                    , T.underline

                    -- Dark mode
                    ------------
                    , T.dark__text_gray_500
                    ]

        -- Paragraph
        , paragraph =
            Html.p
                [ T.inline
                , T.md__block
                ]
    }
