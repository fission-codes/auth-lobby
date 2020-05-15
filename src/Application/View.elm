module View exposing (..)

import Account.Creation.Context
import Account.Creation.View
import Branding
import Html exposing (Html)
import Html.Attributes as A
import Page exposing (Page(..))
import Radix exposing (Model, Msg(..))
import Styling as S
import Tailwind as T



-- 🖼


view : Model -> List (Html Msg)
view model =
    [ Html.div
        [ T.flex
        , T.font_body
        , T.items_center
        , T.justify_center
        , T.min_h_screen
        , T.w_screen

        -- Dark mode
        ------------
        , T.dark__bg_darkness
        ]
        [ case model.page of
            Choose ->
                choose model

            Create context ->
                Account.Creation.View.view context model

            Link ->
                Html.text "Linking new device 📱"
        ]
    ]



-- CHOOSE


choose model =
    Html.div
        [ T.text_gray_300
        , T.text_center

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]
        [ Branding.logo

        -----------------------------------------
        -- Message
        -----------------------------------------
        , Html.div
            [ T.max_w_lg
            , T.mt_10
            , T.mx_auto
            ]
            [ Html.text "It doesn't look like you've signed in on this device before."
            , Html.br [] []
            , Html.text "If you don't know what Fission is, learn more on "
            , Html.a
                [ A.href "https://fission.codes"
                , T.text_gray_100
                , T.underline

                -- Dark mode
                ------------
                , T.dark__text_gray_500
                ]
                [ Html.text "our website" ]
            , Html.text "."
            ]

        -----------------------------------------
        -- Buttons
        -----------------------------------------
        , Html.div
            [ T.flex
            , T.items_center
            , T.justify_center
            , T.mt_10
            , T.mx_auto
            ]
            [ S.buttonLink
                [ A.href (Page.toPath <| Page.Create Account.Creation.Context.default)
                , T.bg_gray_200

                -- Dark mode
                ------------
                , T.dark__bg_purple_shade
                ]
                [ Html.text "Create account" ]

            --
            , S.button
                [ T.bg_gray_400
                , T.ml_3

                -- Dark mode
                ------------
                , T.dark__bg_gray_200
                ]
                [ Html.text "Sign in" ]
            ]
        ]
