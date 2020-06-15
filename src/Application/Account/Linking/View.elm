module Account.Linking.View exposing (..)

import Account.Linking.Context exposing (..)
import Branding
import Common exposing (ifThenElse)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Radix exposing (Model, Msg(..))
import Styling as S
import Tailwind as T



-- 🖼


view : Context -> Model -> Html Msg
view =
    formWithToppings



-- FORM


formWithToppings : Context -> Model -> Html Msg
formWithToppings context model =
    Html.div
        []
        [ Branding.logo { usedUsername = model.usedUsername }
        , form context
        ]


form : Context -> Html Msg
form context =
    Html.form
        [ -- E.onSubmit (CreateAccount context)
          --
          T.max_w_sm
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
        , let
            enteredUsername =
                String.trim context.username /= ""
          in
          S.button
            [ T.bg_gray_200
            , T.block
            , T.duration_75
            , S.default_transition_easing
            , T.mt_6
            , T.transition_opacity
            , T.w_full

            --
            , ifThenElse enteredUsername T.opacity_100 T.opacity_0
            , ifThenElse enteredUsername T.pointer_events_auto T.pointer_events_none

            -- Dark mode
            ------------
            , T.dark__bg_purple_shade
            ]
            [ Html.text "Link account" ]
        ]
