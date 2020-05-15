module Branding exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Tailwind as T


logo : Html msg
logo =
    Html.div
        [ T.relative ]
        [ Html.img
            [ A.src "images/logo-dark-gray-textonly.svg"

            --
            , T.max_w_xs
            , T.mx_auto
            , T.w_full
            ]
            []

        --
        , Html.div
            [ A.style "font-size" "11px"
            , A.style "padding" "3px 4px 2px 5px"

            --
            , T.absolute
            , T.bg_pink
            , T.font_display
            , T.font_medium
            , T.neg_translate_x_2
            , T.right_0
            , T.rounded
            , T.top_0
            , T.text_xs
            , T.text_white
            , T.tracking_widest
            , T.transform
            , T.uppercase
            ]
            [ Html.text "Auth"
            ]
        ]
