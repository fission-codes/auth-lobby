module Account.Creation.View exposing (..)

import Account.Creation.Context exposing (..)
import Account.Linking.Context as LinkingContext
import Account.Linking.QRCode
import Account.Linking.View
import Branding
import Common exposing (ifThenElse)
import External.Context
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Icons
import Loading
import Page
import Radix exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Styling as S
import Tailwind as T



-- 🖼


view : Context -> Model -> Html Msg
view context model =
    case model.reCreateAccount of
        Failure err ->
            formWithToppings (Just err) context model

        Loading ->
            creatingAccount

        NotAsked ->
            formWithToppings Nothing context model

        Success _ ->
            needsLink context model



-- ⏲


creatingAccount : Html msg
creatingAccount =
    [ Html.text "Just a moment, creating your account." ]
        |> Html.div [ T.italic, T.mt_3 ]
        |> List.singleton
        |> Loading.screen



-- FORM


formWithToppings : Maybe String -> Context -> Model -> Html Msg
formWithToppings maybeError context model =
    Html.div
        [ T.flex_1 ]
        [ Branding.logo model
        , form model.dataRootDomain maybeError context
        ]


form : String -> Maybe String -> Context -> Html Msg
form dataRootDomain maybeError context =
    Html.form
        [ E.onSubmit (CreateAccount context)

        --
        , T.max_w_sm
        , T.mt_8
        , T.mx_auto
        , T.w_full
        ]
        [ -----------------------------------------
          -- Email
          -----------------------------------------
          S.label
            [ A.for "email" ]
            [ Html.text "Email" ]
        , S.textField
            [ A.id "email"
            , A.placeholder "doctor@who.tv"
            , A.required True
            , A.type_ "email"
            , A.value context.email
            , E.onInput GotCreateEmailInput
            , T.w_full
            ]
            []

        -----------------------------------------
        -- Username
        -----------------------------------------
        , S.label
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
            , E.onInput GotCreateUsernameInput
            , T.w_full
            ]
            []
        , usernameMessage dataRootDomain context

        -----------------------------------------
        -- Sign Up
        -----------------------------------------
        , let
            isKindOfValid =
                context.usernameIsValid
                    && (context.usernameIsAvailable /= Success False)
                    && (maybeError == Nothing)
          in
          S.button
            [ T.block
            , T.mt_6
            , T.w_full

            --
            , if isKindOfValid then
                T.bg_gray_200

              else
                T.bg_red

            -- Dark mode
            ------------
            , if isKindOfValid then
                T.dark__bg_purple_shade

              else
                T.dark__bg_red
            ]
            [ Html.text "Get started" ]

        -----------------------------------------
        -- Error or sign-in link
        -----------------------------------------
        , case maybeError of
            Just err ->
                S.formError [] [ Html.text err ]

            Nothing ->
                [ Html.text "Can I sign in instead?" ]
                    |> Html.span
                        [ LinkingContext.default
                            |> Page.LinkAccount
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


usernameMessage : String -> Context -> Html Msg
usernameMessage dataRootDomain context =
    let
        username =
            String.trim context.username

        ( isValid, isAvailable ) =
            ( context.usernameIsValid
            , context.usernameIsAvailable == Success True
            )

        checking =
            isValid && context.usernameIsAvailable == Loading

        isFaulty =
            not isValid || (not checking && not isAvailable)

        hidden =
            username == "" || context.usernameIsAvailable == NotAsked
    in
    Html.div
        [ T.items_center
        , T.leading_tight
        , T.mt_3
        , T.opacity_75
        , T.rounded
        , T.text_tiny
        , T.tracking_tight

        --
        , ifThenElse hidden T.hidden T.flex
        , ifThenElse isFaulty T.text_red T.text_inherit
        , ifThenElse isFaulty T.dark__text_pink_tint T.dark__text_inherit
        ]
        [ FeatherIcons.globe
            |> FeatherIcons.withSize 16
            |> Icons.wrap [ T.mr_2, T.opacity_60 ]

        --
        , if hidden then
            Html.text ""

          else if checking then
            Html.span [ T.antialiased ] [ Html.text "Checking if username is available ..." ]

          else if not isValid then
            Html.span
                []
                [ Html.span [ T.antialiased ] [ Html.text "Sorry, " ]
                , Html.strong [ T.break_all ] [ Html.text username ]
                , Html.span [ T.antialiased ] [ Html.text " is not a valid username. You can use letters, numbers and hyphens in between." ]
                ]

          else if not isAvailable then
            Html.span
                []
                [ Html.span [ T.antialiased ] [ Html.text "The username " ]
                , Html.strong [ T.break_all ] [ Html.text username ]
                , Html.span [ T.antialiased ] [ Html.text " is sadly not available." ]
                ]

          else
            Html.span
                []
                [ Html.span [ T.antialiased ] [ Html.text "Your personal address will be " ]
                , Html.strong [ T.break_all ] [ Html.text username, Html.text ".", Html.text dataRootDomain ]
                ]
        ]



-- LINKING


needsLink context model =
    Html.div
        [ T.flex_1 ]
        [ Branding.logo model
        , S.messageBlock
            [ T.italic ]
            [ S.highlightBlock
                [ T.inline_flex, T.items_center ]
                [ S.buttonIcon FeatherIcons.key
                , Html.span
                    []
                    [ Html.text "Your account is ready!"
                    ]
                ]

            --
            , Html.div
                [ T.leading_relaxed
                , T.mx_auto
                , T.max_w_md
                , T.opacity_50
                ]
                [ Html.text "Your browser holds the unique, private key to this account, so you don’t need a password. In order to not get locked out of your account, "
                , Html.span
                    [ T.font_semibold ]
                    [ Html.text "we recommend that you link to at least one other device" ]
                , Html.text ", like your phone, tablet, or other computer with a web browser."
                ]
            , -----------------------------------------
              -- Waiting
              -----------------------------------------
              if context.waitingForDevices then
                Html.div
                    []
                    [ Html.div
                        [ T.mt_5 ]
                        [ Html.text "Open this page on your other device and sign in with “"
                        , Html.span
                            [ T.font_semibold
                            , T.text_black

                            -- Dark mode
                            ------------
                            , T.dark__text_white
                            ]
                            [ Html.text context.username ]
                        , Html.text "”"
                        ]

                    --
                    , Account.Linking.View.qrOrUrlView model.url

                    --
                    , Html.div
                        [ T.mt_6
                        , T.mx_auto
                        , T.max_w_md
                        , T.opacity_50
                        ]
                        [ Loading.animation { size = 18 }
                        ]

                    --
                    , S.subtleFootNote
                        [ Html.span
                            [ E.onClick SkipLinkDuringSetup

                            --
                            , T.cursor_pointer
                            , T.underline
                            , T.underline_thick
                            ]
                            [ Html.text "Remind me later" ]
                        , Html.br [] []
                        , Html.a
                            [ A.href "https://guide.fission.codes/accounts"
                            , A.target "_blank"

                            --
                            , T.cursor_pointer
                            , T.underline
                            , T.underline_thick
                            ]
                            [ Html.text "Read more about how Fission accounts work" ]
                        ]
                    ]

              else
                -----------------------------------------
                -- Linking
                -----------------------------------------
                Account.Linking.View.errorOrExchange Html.nothing context.exchange model
            ]
        ]
