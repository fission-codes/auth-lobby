module Loading exposing (..)

import FeatherIcons
import Html exposing (Html)
import Icons
import Tailwind as T


animation : { size : Int } -> Html msg
animation =
    animationWithAttributes [ T.text_gray_300 ]


animationWithAttributes : List (Html.Attribute msg) -> { size : Int } -> Html msg
animationWithAttributes attributes { size } =
    FeatherIcons.loader
        |> FeatherIcons.withSize (toFloat size)
        |> Icons.wrap
            (List.append
                [ T.animate_spin
                , T.inline_block
                ]
                attributes
            )


screen : List (Html msg) -> Html msg
screen additionalNodes =
    Html.div
        [ T.flex
        , T.flex_col
        , T.min_h_screen_alt
        ]
        [ Html.div
            [ T.flex
            , T.flex_auto
            , T.flex_col
            , T.items_center
            , T.justify_center
            , T.p_8
            , T.text_center
            ]
            (animation { size = 24 } :: additionalNodes)
        ]
