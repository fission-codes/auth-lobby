module Account.Creation.View exposing (..)

import Account.Creation.Context exposing (..)
import Account.Linking.Context as LinkingContext
import Branding
import Common exposing (ifThenElse)
import External.Context
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
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
            creatingAccount



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
        [ Branding.logo { usedUsername = model.usedUsername }
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
        [ -- Email
          --------
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

        -- Username
        -----------
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

        -- Sign Up
        ----------
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

        --
        , case maybeError of
            Just err ->
                Html.div
                    [ T.italic
                    , T.mt_4
                    , T.text_red
                    , T.text_sm
                    ]
                    [ Html.text err ]

            Nothing ->
                [ Html.text "Can I sign in instead?" ]
                    |> Html.span
                        [ LinkingContext.default
                            |> Page.LinkAccount
                            |> GoToPage
                            |> E.onClick

                        --
                        , T.cursor_pointer
                        , T.italic
                        , T.text_center
                        , T.text_gray_300
                        , T.text_sm
                        , T.underline
                        ]
                    |> List.singleton
                    |> Html.div
                        [ T.mt_3
                        , T.text_center
                        ]
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
