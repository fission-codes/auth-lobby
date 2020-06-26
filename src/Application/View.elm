module View exposing (..)

import Account.Creation.Context
import Account.Creation.View
import Account.Linking.Context
import Account.Linking.View
import Authorisation.Performing.View
import Authorisation.Suggest.View
import Branding
import Common
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

                    Page.LinkAccount a ->
                        Account.Linking.View.view a model

                    Page.PerformingAuthorisation ->
                        Authorisation.Performing.View.view model

                    Page.SuggestAuthorisation ->
                        Authorisation.Suggest.View.view context model

            Loading ->
                { defaultFailedState | required = True }
                    |> Failure
                    |> External.Context.note

            NotAsked ->
                case model.usedUsername of
                    Just username ->
                        case model.page of
                            Page.LinkAccount a ->
                                Account.Linking.View.view a model

                            _ ->
                                authenticated username model

                    Nothing ->
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

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]
        [ Branding.logo { usedUsername = model.usedUsername }

        -----------------------------------------
        -- Message
        -----------------------------------------
        , S.messageBlock
            []
            [ Html.text "It doesn't look like you've signed in on this device before."
            , Html.br [ T.hidden, T.sm__block ] []
            , Html.span [ T.sm__hidden ] [ Html.text " " ]
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
                [ T.bg_gray_200

                --
                , Account.Creation.Context.default
                    |> Page.CreateAccount
                    |> GoToPage
                    |> E.onClick

                -- Dark mode
                ------------
                , T.dark__bg_purple_shade
                ]
                [ Html.text "Create account" ]

            --
            , S.button
                [ T.bg_gray_400
                , T.ml_3

                --
                , Account.Linking.Context.default
                    |> Page.LinkAccount
                    |> GoToPage
                    |> E.onClick

                -- Dark mode
                ------------
                , T.dark__bg_gray_200
                ]
                [ Html.text "Sign in" ]
            ]
        ]



-- AUTHENTICATED


authenticated : String -> Model -> Html Msg
authenticated username model =
    Html.div
        [ T.text_center ]
        [ Branding.logo { usedUsername = model.usedUsername }

        --
        , S.messageBlock
            []
            [ Html.div
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
                , T.dark__bg_darkness_above
                , T.dark__text_purple_tint
                ]
                [ Html.span
                    [ T.opacity_90 ]
                    [ Html.text "Authenticated as " ]
                , Html.span
                    [ T.inline_block
                    , T.mx_px
                    , T.text_purple

                    -- Dark mode
                    ------------
                    , T.dark__text_gray_700
                    ]
                    [ Html.text username ]
                ]
            , Html.br [] []
            , Html.em [] [ Html.text "Keep this window open if you want" ]
            , Html.br [] []
            , Html.em [] [ Html.text "to authenticate on another device." ]
            ]
        ]
