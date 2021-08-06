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
import Svg
import Svg.Attributes
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
                        , T.mt_8
                        , T.text_center
                        ]
                        [ Html.div
                            [ T.border_t
                            , T.border_base_200
                            , T.pt_5

                            -- Dark mode
                            ------------
                            , T.dark__border_base_700
                            ]
                            [ Html.a
                                [ A.href "https://fission.codes"
                                , A.target "_blank"

                                --
                                , T.inline_flex
                                , T.items_center
                                , T.justify_center
                                , T.text_base_400
                                , T.text_xs
                                ]
                                [ Html.span
                                    [ T.mr_px
                                    ]
                                    [ Html.text "Powered by" ]
                                , Html.span
                                    [ A.title "Fission"
                                    , T.inline_block
                                    , T.ml_1
                                    ]
                                    [ fissionBadge ]
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


fissionBadge =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 640 640"
        , Svg.Attributes.width "13"
        ]
        [ Svg.path
            [ Svg.Attributes.fill "currentColor"
            , Svg.Attributes.fillRule "evenodd"
            , Svg.Attributes.d "m0 320a319.58 319.58 0 0 1 320-320c176.14 0 320 142.94 320 320a320 320 0 0 1 -640 0zm384.88 116c0 44.12 36.33 80.45 80.44 80.45 45 0 80.45-35.47 78.72-81.32 0-44.11-36.33-80.44-80.45-80.44-20.76 0-40.65 8.65-56.22 23.35-23.36-12.11-49.31-21.62-77-28.54 2.41-6.64 7.77-22.94 12.26-36.61 1.95-5.93 3.73-11.37 5-15.29a368.77 368.77 0 0 0 43.25 5.18c55.36 4.33 96-6.05 122.84-30.27s32-57.09 32-79.58c0-54.5-45-99.48-99.48-99.48h-.75c-5.59-.2-35.52-1.26-62.39 19.91-18.1 14.64-41.47 75.2-58.77 125.37-26-6.92-49.31-16.43-69.21-29.41v-5.19c0-44.11-36.33-80.45-80.44-80.45s-80.45 36.32-80.45 80.45 36.33 80.45 80.45 80.45c20.76 0 40.65-8.65 56.22-23.36 23.36 12.11 49.31 21.63 78.72 29.41-2.41 6.64-7.77 22.95-12.26 36.61-1.95 5.93-3.73 11.37-5 15.3a366.68 366.68 0 0 0 -43.25-5.19c-55.36-4.33-96 6-122.84 30.27s-32 57.09-32 79.58c0 54.5 45 99.48 99.48 99.48h5.19c11.24 0 35.46-1.73 58-19.89 18.17-14.71 41.52-75.26 58.82-125.43 26 6.92 49.31 16.43 69.21 29.41zm114.18-207.65c9.51-10.35 12.94-24.22 11.24-42.35-2.59-19.9-24.22-72.66-52.76-78.72q-23.35-5.19-46.71 33.74-18.16 37.62-44.12 106.4l23.36 2.58c55.36 3.43 91.69-3.49 108.99-21.65zm-275.95 160.89c-40.65 0-68.33 7.79-82.17 22.49-9.52 10.38-13 24.22-11.25 42.39 2.6 19.9 24.22 72.66 52.77 78.72q23.35 5.19 46.71-33.74 18.17-37.62 44.12-106.4l-23.36-2.59c-4.87 0-9.51-.23-14.05-.45-4.32-.21-8.54-.42-12.77-.42z"
            ]
            []
        ]



-- CHOOSE


choose : Model -> Html Msg
choose model =
    Html.div
        [ T.text_base_500

        -- Dark mode
        ------------
        , T.dark__text_base_400
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
            , T.mt_8
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
                [ T.bg_base_400
                , T.ml_3

                --
                , Account.Linking.Context.default
                    |> Page.LinkAccount
                    |> GoToPage
                    |> E.onClick

                -- Dark mode
                ------------
                , T.dark__bg_base_600
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
                , T.border_base_200
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
