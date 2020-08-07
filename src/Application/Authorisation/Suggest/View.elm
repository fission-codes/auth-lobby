module Authorisation.Suggest.View exposing (view)

import Branding
import Dict
import External.Context exposing (Context, Resource(..), defaultFailedState)
import FeatherIcons
import Html exposing (Html)
import Html.Events as E
import Icons
import Loading
import Maybe.Extra as Maybe
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Styling as S
import Tailwind as T
import Time
import Time.Distance
import Time.Distance.I18n



-- 🖼


view : Context -> Model -> Html Msg
view context model =
    Html.div
        [ T.text_center ]
        [ Branding.logo { usedUsername = model.usedUsername }

        -----------------------------------------
        -- Name & Duration
        -----------------------------------------
        , Html.div
            [ T.mt_10 ]
            [ Html.span
                [ T.font_semibold ]
                [ Html.text context.redirectTo.host
                , Html.text (Maybe.unwrap "" (String.fromInt >> (++) ":") context.redirectTo.port_)
                ]

            --
            , Html.text " would like to have access to the following"

            --
            , Html.text " for "
            , Html.text <|
                Time.Distance.inWordsWithConfig
                    { withAffix = False }
                    Time.Distance.I18n.en
                    (Time.millisToPosix 0)
                    (Time.millisToPosix <| context.lifetimeInSeconds * 1000)
            , Html.text ":"
            ]

        -----------------------------------------
        -- Resources
        -----------------------------------------
        , Html.ul
            [ T.italic
            , T.leading_snug
            , T.max_w_md
            , T.mt_6
            , T.mx_auto
            , T.rounded_md
            , T.shadow
            , T.text_gray_200
            , T.text_left
            , T.text_sm

            -- Dark mode
            ------------
            , T.dark__text_gray_400
            ]
            (case context.resource of
                Everything ->
                    [ resourceItem
                        [ T.bg_red
                        , T.text_white
                        ]
                        [ resourceIcon FeatherIcons.alertTriangle
                        , Html.text "Your entire Fission account"
                        ]
                    ]

                Resources resources ->
                    resources
                        |> Dict.toList
                        |> List.sortWith
                            (\( a, x ) ( b, y ) ->
                                case ( a == b, a, b ) of
                                    ( True, _, _ ) ->
                                        compare x y

                                    ( False, "app", _ ) ->
                                        compare a b

                                    ( False, "domain", _ ) ->
                                        compare a b

                                    ( False, "wnfs", _ ) ->
                                        compare a b

                                    ( False, _, "app" ) ->
                                        GT

                                    ( False, _, "domain" ) ->
                                        GT

                                    ( False, _, "wnfs" ) ->
                                        GT

                                    _ ->
                                        compare x y
                            )
                        |> List.map
                            (\( key, value ) ->
                                case key of
                                    "app" ->
                                        [ resourceIcon FeatherIcons.box
                                        , Html.span
                                            []
                                            [ Html.text "Your Fission app "
                                            , Html.strong [] [ Html.text value ]
                                            ]
                                        ]

                                    "domain" ->
                                        [ resourceIcon FeatherIcons.globe
                                        , Html.span
                                            []
                                            [ Html.text "Your Fission user domain "
                                            , Html.strong [] [ Html.text value ]
                                            ]
                                        ]

                                    "wnfs" ->
                                        [ resourceIcon FeatherIcons.hardDrive
                                        , Html.span
                                            []
                                            [ Html.strong [] [ Html.text value ]
                                            , Html.text " in your file system"
                                            ]
                                        ]

                                    _ ->
                                        [ resourceIcon FeatherIcons.lock
                                        , Html.span
                                            []
                                            [ Html.text (key ++ ": ")
                                            , Html.strong [] [ Html.text value ]
                                            ]
                                        ]
                            )
                        |> List.map
                            (resourceItem
                                [ T.bg_gray_800

                                -- Dark mode
                                ------------
                                , T.dark__bg_darkness_below
                                ]
                            )
            )

        -----------------------------------------
        -- Buttons
        -----------------------------------------
        , Html.div
            [ T.flex
            , T.justify_center
            , T.mt_10
            ]
            [ S.button
                [ E.onClick AllowAuthorisation

                --
                , T.bg_purple
                , T.flex
                , T.items_center

                -- Dark mode
                ------------
                , T.dark__bg_purple_shade
                ]
                [ S.buttonIcon FeatherIcons.check
                , Html.text "Yes"
                ]

            --
            , S.button
                [ E.onClick DenyAuthorisation

                --
                , T.bg_gray_400
                , T.flex
                , T.items_center
                , T.ml_3

                -- Dark mode
                ------------
                , T.dark__bg_gray_200
                ]
                [ S.buttonIcon FeatherIcons.x
                , Html.text "No"
                ]
            ]
        ]



-- ㊙️


resourceIcon icon =
    icon
        |> FeatherIcons.withSize 14
        |> Icons.wrap [ T.mr_3, T.opacity_60 ]


resourceItem additionalClasses nodes =
    Html.li
        (List.append
            [ T.border_b
            , T.border_black
            , T.border_opacity_05

            --
            , T.first__pt_px
            , T.first__rounded_t_md
            , T.last__border_transparent
            , T.last__rounded_b_md

            -- Dark mode
            ------------
            , T.dark__border_white
            , T.dark__border_opacity_025
            ]
            additionalClasses
        )
        [ Html.div
            [ T.flex
            , T.items_center
            , T.px_4
            , T.py_5
            ]
            nodes
        ]
