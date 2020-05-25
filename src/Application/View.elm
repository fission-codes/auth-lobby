module View exposing (..)

import Account.Creation.Context
import Account.Creation.View
import Branding
import External.Context
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Loading
import Page
import Radix exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Styling as S
import Tailwind as T



-- 🖼


view : Model -> List (Html Msg)
view model =
    [ Html.div
        [ T.flex
        , T.items_center
        , T.justify_center
        , T.min_h_screen
        , T.w_screen
        ]
        [ case model.page of
            Page.Choose ->
                choose model

            Page.CreateAccount context ->
                Account.Creation.View.view context model

            Page.LinkAccount ->
                Html.text "Under construction 🚜"

            Page.LinkingApplication ->
                case model.externalContext of
                    Failure () ->
                        External.Context.note model.externalContext

                    Success _ ->
                        [ Html.text "Just a moment, granting access." ]
                            |> Html.div [ T.italic, T.mt_3 ]
                            |> List.singleton
                            |> Loading.screen

                    _ ->
                        External.Context.note (Failure ())
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
            [ S.button
                [ E.onClick (GoToPage <| Page.CreateAccount Account.Creation.Context.default)
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
