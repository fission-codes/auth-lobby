module Authorisation.Suggest.View exposing (view)

import Branding
import External.Context exposing (Context, defaultFailedState)
import FeatherIcons
import Html exposing (Html)
import Html.Events as E
import Icons
import Loading
import Maybe.Extra as Maybe
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Styling as S
import Tailwind as T



-- 🖼


view : Context -> Model -> Html Msg
view context model =
    Html.div
        [ T.text_center ]
        [ Branding.logo { usedUsername = model.usedUsername }

        --
        , Html.div
            [ T.mt_10 ]
            [ Html.text "Should I allow "
            , Html.span
                [ T.font_semibold ]
                [ Html.text context.redirectTo.host
                , Html.text (Maybe.unwrap "" (String.fromInt >> (++) ":") context.redirectTo.port_)
                ]
            , Html.text " access to your entire file system for a month?"
            ]

        --
        , Html.div
            [ T.flex
            , T.justify_center
            , T.mt_10
            ]
            [ S.button
                [ E.onClick AllowAuthorisation

                --
                , T.bg_gray_200
                , T.flex
                , T.items_center

                -- Dark mode
                ------------
                , T.dark__bg_purple_shade
                ]
                [ dialogButtonIcon FeatherIcons.check
                , Html.text "Yes"
                ]

            --
            , S.button
                [ E.onClick DenyAuthorisation

                --
                , T.bg_gray_400
                , T.flex
                , T.items_center
                , T.ml_3

                -- Dark mode
                ------------
                , T.dark__bg_gray_200
                ]
                [ dialogButtonIcon FeatherIcons.x
                , Html.text "No"
                ]
            ]
        ]


dialogButtonIcon : FeatherIcons.Icon -> Html Msg
dialogButtonIcon icon =
    Icons.wrap [ T.mr_2 ] (FeatherIcons.withSize 16 icon)
