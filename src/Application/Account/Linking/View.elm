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
view context model =
    Html.div
        []
        [ Branding.logo { usedUsername = model.usedUsername }

        --
        , if context.waitingForDevices then
            Html.div
                []
                [ Html.text "Open this website on your other device" ]

          else
            form context
        ]



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
            [ T.bg_gray_200
            , T.block
            , T.mt_6
            , T.w_full

            -- Dark mode
            ------------
            , T.dark__bg_purple_shade
            ]
            [ Html.text "Link account" ]
        ]
