module Styling exposing (..)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Icons
import Tailwind as T



-- 🧩


type alias Node msg =
    List (Html.Attribute msg) -> List (Html msg) -> Html msg



-- 🖼


container_padding =
    T.px_6


default_light_text_color =
    T.text_base_700


default_dark_text_color =
    T.dark__text_base_300


default_transition_duration =
    T.duration_500


default_transition_easing =
    T.ease_out


iconSize =
    22



-- 🍱


button : Node msg
button =
    buttonWithNode Html.button


buttonIcon : FeatherIcons.Icon -> Html msg
buttonIcon icon =
    Icons.wrap [ T.mr_2 ] (FeatherIcons.withSize 16 icon)


buttonLink : Node msg
buttonLink =
    buttonWithNode Html.a


buttonWithNode : Node msg -> Node msg
buttonWithNode node attributes =
    attributes
        |> List.append
            [ T.antialiased
            , T.appearance_none
            , T.font_semibold
            , T.leading_normal
            , T.px_5
            , T.py_3
            , T.relative
            , T.rounded
            , T.text_sm
            , T.text_white
            , T.tracking_wider
            , T.transition_colors
            , T.uppercase

            --
            , default_transition_duration
            , default_transition_easing
            ]
        |> node


clickToCopy : String -> msg -> Html msg
clickToCopy text msg =
    Html.div
        [ A.title "Click to copy"
        , E.onClick msg

        --
        , T.border_2
        , T.border_dashed
        , T.border_base_300
        , T.cursor_pointer
        , T.inline_flex
        , T.italic
        , T.items_center
        , T.mt_6
        , T.opacity_80
        , T.p_5
        , T.rounded_md

        -- Dark mode
        ------------
        , T.dark__border_base_600
        ]
        [ buttonIcon FeatherIcons.scissors
        , Html.text text
        ]


formError : Node msg
formError attributes =
    attributes
        |> List.append
            [ T.flex
            , T.italic
            , T.items_center
            , T.justify_center
            , T.mt_6
            , T.text_red
            , T.text_sm
            ]
        |> Html.div


highlightBlock : Node msg
highlightBlock attributes =
    attributes
        |> List.append
            [ T.bg_purple_tint
            , T.border_t
            , T.border_transparent
            , T.inline_block
            , T.mb_6
            , T.p_5
            , T.rounded_md
            , T.text_purple_shade

            -- Dark mode
            ------------
            , T.dark__bg_purple_shade
            , T.dark__bg_opacity_20
            , T.dark__text_purple_tint
            ]
        |> Html.div


label : Node msg
label attributes =
    attributes
        |> List.append
            [ T.block
            , T.font_bold
            , T.pb_1
            , T.text_base_600
            , T.text_xs
            , T.tracking_wide
            , T.uppercase

            -- Dark mode
            ------------
            , T.dark__text_base_500
            ]
        |> Html.label


messageBlock : Node msg
messageBlock attributes =
    attributes
        |> List.append
            [ T.max_w_lg
            , T.mt_10
            , T.mx_auto
            , T.text_center
            ]
        |> Html.div


subtleFootNote : List (Html msg) -> Html msg
subtleFootNote =
    Html.div
        [ T.mt_6
        , T.mx_auto
        , T.not_italic
        , T.opacity_75
        , T.text_base_400
        , T.text_xs
        ]


textField : Node msg
textField attributes =
    attributes
        |> List.append
            [ A.attribute "autocapitalize" "off"

            --
            , T.appearance_none
            , T.bg_transparent
            , T.border_2
            , T.border_base_300
            , T.flex_auto
            , T.leading_relaxed
            , T.outline_none
            , T.px_4
            , T.py_2
            , T.rounded
            , T.text_inherit
            , T.text_base
            , T.transition_colors

            --
            , default_transition_duration
            , default_transition_easing

            -- Dark mode
            ------------
            , T.dark__border_base_600
            ]
        |> Html.input


warning : List (Html msg) -> Html msg
warning nodes =
    Html.div
        [ T.break_all
        , T.flex
        , T.items_center
        , T.max_w_sm
        , T.mt_8
        , T.mx_auto
        , T.neg_mb_3
        , T.text_red
        , T.text_sm
        ]
        [ FeatherIcons.alertTriangle
            |> FeatherIcons.withSize 18
            |> Icons.wrap [ T.flex_shrink_0 ]

        --
        , Html.div
            [ T.ml_2, T.pl_px ]
            nodes
        ]
