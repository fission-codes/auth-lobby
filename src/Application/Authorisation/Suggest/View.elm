module Authorisation.Suggest.View exposing (view)

import Authorisation.Suggest.Resource as Resource
import Branding
import Dict
import External.Context exposing (Context, defaultFailedState)
import FeatherIcons
import Html exposing (Html)
import Html.Events as E
import Html.Extra as Html
import Icons
import List.Ext as List
import Loading
import Maybe.Extra as Maybe
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Styling as S
import Tailwind as T
import Time
import Time.Distance
import Time.Distance.I18n



-- 🖼


view : Context -> Model -> Html Msg
view context model =
    Html.div
        [ T.text_center ]
        [ Branding.logo { usedUsername = model.usedUsername }

        -----------------------------------------
        -- Name & Duration
        -----------------------------------------
        , Html.div
            [ T.mt_10 ]
            [ Html.text "Allow "
            , Html.span
                [ T.font_semibold ]
                [ Html.text context.redirectTo.host
                , Html.text (Maybe.unwrap "" (String.fromInt >> (++) ":") context.redirectTo.port_)
                ]

            --
            , Html.text " access to the following for "
            , Html.text <|
                Time.Distance.inWordsWithConfig
                    { withAffix = False }
                    Time.Distance.I18n.en
                    (Time.millisToPosix 0)
                    (Time.millisToPosix <| context.lifetimeInSeconds * 1000)

            --
            , Html.text "?"
            ]

        -----------------------------------------
        -- Resources
        -----------------------------------------
        , [ Maybe.unwrap Html.nothing Resource.applicationFolder context.app
          ]
            |> List.prepend
                (List.map
                    (Resource.fileSystemPath Resource.Private)
                    context.privatePaths
                )
            |> List.prepend
                (List.map
                    (Resource.fileSystemPath Resource.Public)
                    context.publicPaths
                )
            |> Html.ul
                [ T.italic
                , T.leading_snug
                , T.max_w_md
                , T.mt_6
                , T.mx_auto
                , T.rounded_md
                , T.shadow
                , T.text_gray_200
                , T.text_left
                , T.text_sm

                -- Dark mode
                ------------
                , T.dark__text_gray_400
                ]

        -----------------------------------------
        -- Buttons
        -----------------------------------------
        , Html.div
            [ T.flex
            , T.justify_center
            , T.mt_10
            ]
            [ S.button
                [ E.onClick AllowAuthorisation

                --
                , T.bg_purple
                , T.flex
                , T.items_center

                -- Dark mode
                ------------
                , T.dark__bg_purple_shade
                ]
                [ S.buttonIcon FeatherIcons.check
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
                [ S.buttonIcon FeatherIcons.x
                , Html.text "No"
                ]
            ]
        ]
