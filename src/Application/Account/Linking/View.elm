module Account.Linking.View exposing (..)

import Account.Creation.Context
import Account.Linking.Context exposing (..)
import Account.Linking.Progress exposing (..)
import Account.Linking.QRCode
import Branding
import Common
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Icons
import Kit.Components as Kit
import Page
import Radix exposing (Model, Msg(..))
import Styling as S
import Tailwind as T
import Url exposing (Url)



-- 🖼


view : Context -> Model -> Html Msg
view context model =
    Html.div
        [ T.flex_1 ]
        [ Branding.logo model

        --
        , if context.waitingForDevices then
            S.messageBlock
                [ T.italic ]
                [ Html.div
                    []
                    [ Html.text "Open this website on your other device to authenticate this one." ]

                --
                , qrOrUrlView model.url

                --
                , S.subtleFootNote
                    [ Html.text "Authenticating with "
                    , Html.span
                        [ T.border_b, T.border_base_200 ]
                        [ Html.text context.username ]
                    ]
                ]

          else
            exchangeView (form context) context model
        ]


qrOrUrlView : Url -> Html Msg
qrOrUrlView url =
    Html.div
        []
        [ Html.div
            [ T.hidden
            , T.lg__block
            ]
            [ Account.Linking.QRCode.view
                url
                Nothing
            ]

        --
        , Html.div
            [ T.lg__hidden ]
            [ S.clickToCopy
                (Common.urlOrigin url)
                (CopyToClipboard <| Common.urlOrigin url)
            ]
        ]



-- EXCHANGE


exchangeView : Html Msg -> Context -> Model -> Html Msg
exchangeView fallbackView context model =
    -- TODO:
    --     Just ( Authoriser (Delegation []), exchange ) ->
    --         S.messageBlock
    --             [ T.italic ]
    --             [ Html.text "Waiting to hear from your other device."
    --             , Html.br [] []
    --             , Html.text "If you have this page open on more than two devices, close this one."
    --             ]
    --
    case context.progress of
        Just (Consumer (ConsumerPin pin)) ->
            S.messageBlock
                [ T.italic ]
                [ Html.text "Do these numbers match the ones shown on your other device?"
                , numberDisplay pin
                ]

        Just (Producer (ProducerPin pin)) ->
            S.messageBlock
                []
                [ Html.span
                    [ T.italic ]
                    [ Html.text "Confirm these are the numbers shown on your other device." ]

                --
                , numberDisplay pin

                --
                , Html.div
                    [ T.flex
                    , T.justify_center
                    , T.mt_10
                    ]
                    [ S.button
                        [ E.onClick ConfirmProducerPin

                        --
                        , T.bg_purple
                        , T.flex
                        , T.items_center
                        ]
                        [ S.buttonIcon FeatherIcons.check
                        , Html.text "Approve"
                        ]

                    --
                    , S.button
                        [ E.onClick CancelLink

                        --
                        , T.bg_base_400
                        , T.flex
                        , T.items_center
                        , T.ml_3

                        -- Dark mode
                        ------------
                        , T.dark__bg_base_600
                        ]
                        [ S.buttonIcon FeatherIcons.x
                        , Html.text "Cancel"
                        ]
                    ]
                ]

        Just _ ->
            S.messageBlock
                [ T.italic ]
                [ Html.text "Negotiating with your other device."
                , Html.div
                    [ T.flex
                    , T.justify_center
                    , T.mt_6
                    , T.mx_auto
                    , T.max_w_md
                    , T.opacity_50
                    ]
                    [ Kit.loadingAnimation
                        [ T.h_4, T.w_4 ]
                    ]
                ]

        Nothing ->
            fallbackView



-- FORM


form : Context -> Html Msg
form context =
    Html.form
        [ E.onSubmit (LinkAccount context)

        --
        , T.max_w_sm
        , T.mt_8
        , T.mx_auto
        , T.w_full
        ]
        [ -- Username
          -----------
          S.label
            [ A.for "username"
            , T.mt_6
            ]
            [ Html.text "Username" ]
        , S.textField
            [ A.autocomplete False
            , A.id "username"
            , A.placeholder "thedoctor"
            , A.required True
            , A.value context.username
            , E.onInput GotLinkUsernameInput
            , T.w_full
            ]
            []

        -- Sign in
        ----------
        , S.button
            [ T.bg_purple
            , T.block
            , T.mt_8
            , T.w_full
            ]
            [ Html.text "Link account" ]

        --
        , case context.note of
            Just note ->
                S.formError
                    []
                    [ Icons.wrap
                        [ T.mr_1, T.pr_px ]
                        (FeatherIcons.withSize 15 FeatherIcons.alertTriangle)
                    , Html.span
                        [ T.italic ]
                        [ Html.text note ]
                    ]

            Nothing ->
                [ Html.text "Can I create an account instead?" ]
                    |> Html.span
                        [ Account.Creation.Context.default
                            |> Page.CreateAccount
                            |> GoToPage
                            |> E.onClick

                        --
                        , T.cursor_pointer
                        , T.underline
                        ]
                    |> List.singleton
                    |> Html.div [ T.text_center ]
                    |> List.singleton
                    |> S.subtleFootNote
        ]



-- NUMBER DISPLAY


numberDisplay : List Int -> Html Msg
numberDisplay numbers =
    numbers
        |> List.map
            (\n ->
                Html.div
                    [ T.border_2
                    , T.border_base_200
                    , T.leading_normal
                    , T.mr_2
                    , T.opacity_90
                    , T.pt_px
                    , T.rounded_md
                    , T.w_12

                    --
                    , T.last__mr_0

                    -- Dark mode
                    ------------
                    , T.dark__border_base_800

                    -- Responsive
                    -------------
                    , T.sm__w_16
                    ]
                    [ Html.text (String.fromInt n)
                    ]
            )
        |> Html.div
            [ T.antialiased
            , T.flex
            , T.font_display
            , T.font_thin
            , T.justify_center
            , T.leading_normal
            , T.mt_8
            , T.mx_auto
            , T.number_display
            , T.pt_1
            , T.not_italic
            , T.text_4xl
            , T.text_base_600

            -- Dark mode
            ------------
            , T.dark__text_base_400

            -- Responsive
            -------------
            , T.sm__text_5xl
            ]
