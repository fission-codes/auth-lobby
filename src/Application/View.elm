module View exposing (..)

import Account.Creation.Context
import Account.Creation.View
import Authorisation.Performing.View
import Authorisation.Suggest.View
import Branding
import External.Context exposing (Context, defaultFailedState)
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
        , T.px_4
        , T.w_screen
        ]
        [ case model.externalContext of
            Failure _ ->
                External.Context.note model.externalContext

            Success context ->
                case model.page of
                    Page.Choose ->
                        choose model

                    Page.CreateAccount a ->
                        Account.Creation.View.view a model

                    Page.LinkAccount ->
                        Html.text "Under construction 🚜"

                    Page.PerformingAuthorisation ->
                        Authorisation.Performing.View.view model

                    Page.SuggestAuthorisation ->
                        Authorisation.Suggest.View.view context model

            _ ->
                { defaultFailedState | required = True }
                    |> Failure
                    |> External.Context.note
        ]
    ]



-- CHOOSE


choose : Model -> Html Msg
choose model =
    Html.div
        [ T.text_gray_300
        , T.text_center

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]
        [ Branding.logo { usedUsername = model.usedUsername }

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
