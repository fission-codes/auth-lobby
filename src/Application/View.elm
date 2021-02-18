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
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Loading
import Markdown.Parser
import Markdown.Renderer
import Markdown.Renderer.Custom
import Page
import Radix exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Styling as S
import Tailwind as T
import Theme.Defaults



-- 🖼


view : Model -> List (Html Msg)
view model =
    if RemoteData.isLoading model.theme then
        [ Html.text "Just a moment, loading lobby theme." ]
            |> Html.div [ T.italic, T.mt_3 ]
            |> List.singleton
            |> Loading.screen
            |> List.singleton

    else
        view_ model


view_ : Model -> List (Html Msg)
view_ model =
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

                Page.Note a ->
                    note a model

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

                        Page.Note a ->
                            note a model

                        _ ->
                            authenticated username model

                Nothing ->
                    case model.page of
                        Page.Choose ->
                            choose model

                        Page.CreateAccount a ->
                            Account.Creation.View.view a model

                        Page.LinkAccount a ->
                            Account.Linking.View.view a model

                        Page.Note a ->
                            note a model

                        _ ->
                            { defaultFailedState | required = True }
                                |> Failure
                                |> External.Context.note

    -----------------------------------------
    -- Fission Tag
    -----------------------------------------
    , case model.theme of
        Success theme ->
            case theme.logo of
                Just _ ->
                    Html.div
                        [ T.flex
                        , T.justify_center
                        , T.mt_10
                        , T.text_center
                        ]
                        [ Html.div
                            [ T.border_t
                            , T.border_gray_600
                            , T.pt_5

                            -- Dark mode
                            ------------
                            , T.dark__border_gray_100
                            ]
                            [ Html.a
                                [ A.href "https://fission.codes"
                                , A.target "_blank"

                                --
                                , T.inline_flex
                                , T.items_center
                                , T.justify_center
                                , T.text_gray_400
                                , T.text_xs
                                ]
                                [ Html.span
                                    [ T.mr_px
                                    ]
                                    [ Html.text "Powered by" ]
                                , Html.img
                                    [ A.src "/images/badge-solid-faded.svg"
                                    , A.width 14

                                    --
                                    , T.inline_block
                                    , T.ml_1
                                    ]
                                    []
                                ]
                            ]
                        ]

                Nothing ->
                    Html.nothing

        _ ->
            Html.nothing
    ]
        |> Html.div
            [ T.py_6
            , T.w_full
            ]
        |> List.singleton
        |> Html.div
            [ T.flex
            , T.items_center
            , T.justify_center
            , T.min_h_screen_alt
            , T.px_6
            , T.w_screen
            ]
        |> List.singleton



-- CHOOSE


choose : Model -> Html Msg
choose model =
    Html.div
        [ T.text_gray_300

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]
        [ Branding.logo model

        -----------------------------------------
        -- Message
        -----------------------------------------
        , let
            deadEndsToString deadEnds =
                deadEnds
                    |> List.map Markdown.Parser.deadEndToString
                    |> String.join "\n"

            renderedMarkdown =
                model.theme
                    |> RemoteData.toMaybe
                    |> Maybe.andThen .introduction
                    |> Maybe.withDefault Theme.Defaults.introduction
                    |> Markdown.Parser.parse
                    |> Result.mapError deadEndsToString
                    |> Result.andThen (Markdown.Renderer.render Markdown.Renderer.Custom.default)
          in
          S.messageBlock
            []
            (case renderedMarkdown of
                Ok html ->
                    html

                Err err ->
                    [ Html.em
                        [ T.text_red ]
                        [ Html.strong [] [ Html.text "Theme introduction markdown error:" ]
                        , Html.br [] []
                        , Html.text err
                        , Html.br [] []
                        , Html.br [] []
                        , Html.span
                            [ T.inline_flex, T.items_center ]
                            [ S.buttonIcon FeatherIcons.alertTriangle
                            , Html.text "No HTML is allowed."
                            ]
                        ]
                    ]
            )

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
                [ T.bg_purple

                --
                , Account.Creation.Context.default
                    |> Page.CreateAccount
                    |> GoToPage
                    |> E.onClick
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
        [ Branding.logo model

        --
        , S.messageBlock
            []
            [ S.highlightBlock
                [ T.relative ]
                [ Html.span
                    [ T.opacity_90

                    -- Dark mode
                    ------------
                    , T.dark__opacity_60
                    ]
                    [ Html.text "Authenticated as " ]
                , Html.span
                    [ T.inline_block
                    , T.mx_px
                    , T.text_purple

                    -- Dark mode
                    ------------
                    , T.dark__text_purple_tint
                    ]
                    [ Html.text username ]
                ]
            , Html.br [] []
            , Html.em [] [ Html.text "Keep this window open if you want" ]
            , Html.br [] []
            , Html.em [] [ Html.text "to authenticate on another device." ]
            ]

        --
        , S.subtleFootNote
            [ Html.text "If you wish you can also "
            , Html.span
                [ E.onClick Leave

                --
                , T.border_b
                , T.border_gray_600
                , T.cursor_pointer
                ]
                [ Html.text "remove this device"
                ]
            ]
        ]



-- NOTE


note : String -> Model -> Html Msg
note text model =
    Html.div
        [ T.text_center ]
        [ Branding.logo model

        --
        , S.messageBlock
            [ T.italic ]
            (text
                |> String.split "\n"
                |> List.map (\t -> Html.div [] [ Html.text t ])
            )
        ]
