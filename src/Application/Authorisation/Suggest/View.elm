module Authorisation.Suggest.View exposing (view)

import Authorisation.Suggest.Progress as Progress
import Authorisation.Suggest.Resource as Resource
import Branding
import Common exposing (ifThenElse)
import External.Context exposing (Context, defaultFailedState)
import FeatherIcons
import Flow exposing (Flow(..))
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Icons
import Json.Print
import List.Ext as List
import List.Extra as List
import Maybe.Extra as Maybe
import Radix exposing (..)
import Result.Extra as Result
import Styling as S
import Tailwind as T
import Time
import Time.Distance
import Time.Distance.I18n



-- 🖼


view : Context -> Model -> Html Msg
view context model =
    let
        isError =
            Flow.isFailure model.reLinkApp

        isInProgress =
            Flow.isInProgress model.reLinkApp
    in
    Html.div
        [ T.text_center ]
        [ Branding.logo model

        -----------------------------------------
        -- Name & Duration
        -----------------------------------------
        , let
            hasResources =
                Maybe.isJust context.appFolder
                    || not (List.isEmpty context.privatePaths)
                    || not (List.isEmpty context.publicPaths)
                    || not (List.isEmpty context.web)

            hasRawResources =
                Maybe.isJust context.raw

            label =
                Html.span
                    [ T.font_semibold
                    , T.text_black

                    -- Dark mode
                    ------------
                    , T.dark__text_white
                    ]
                    (context
                        |> appNameLabel
                        |> Maybe.withDefault (originLabel context)
                    )
          in
          Html.div
            [ T.mt_8 ]
          <|
            if hasResources then
                [ Html.text "Allow "
                , label

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

            else if hasRawResources then
                [ Html.text "Allow "
                , label

                --
                , Html.text " access to the following resources?"
                ]

            else
                [ Html.text "Allow "
                , label
                , Html.text " to authenticate with this account?"
                ]

        -----------------------------------------
        -- Resources
        -----------------------------------------
        , [ Maybe.unwrap Html.nothing Resource.applicationFolder context.appFolder
          ]
            |> List.append
                (List.map
                    Resource.application
                    context.web
                )
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
            |> List.prepend
                (if context.sharedSection then
                    [ Resource.sharedSection ]

                 else
                    []
                )
            |> List.prepend
                (case context.raw of
                    Just r ->
                        [ rawResource r ]

                    Nothing ->
                        []
                )
            |> S.resourceList

        -- Warnings
        -----------
        , if List.any ((==) "/") context.privatePaths then
            warning
                [ Html.text """
                    This application will have access to all your private files. Make sure you trust this app before you grant permission.
                  """
                , Html.text " "
                , Html.a
                    [ A.href "https://guide.fission.codes/accounts#app-permissions"
                    , A.target "_blank"
                    , T.underline
                    ]
                    [ Html.text "Learn more" ]
                , Html.text ""
                ]

          else
            Html.nothing

        --
        , if List.any ((==) "*") context.web then
            warning
                [ Html.text """
                    This application will have access to all your Fission apps. Make sure you trust this app before you grant permission.
                  """
                , Html.text " "
                , Html.a
                    [ A.href "https://guide.fission.codes/accounts#app-permissions"
                    , A.target "_blank"
                    , T.underline
                    ]
                    [ Html.text "Learn more" ]
                , Html.text ""
                ]

          else
            Html.nothing

        -----------------------------------------
        -- Buttons
        -----------------------------------------
        , Html.div
            [ T.flex
            , T.justify_center
            , T.mt_8
            ]
            [ case model.reLinkApp of
                InProgress progress ->
                    S.progress (Progress.explain progress.progress)

                _ ->
                    S.button
                        [ E.onClick (GetCurrentTime AllowAuthorisation)
                        , A.disabled isInProgress

                        --
                        , ifThenElse isError T.bg_red T.bg_purple
                        , T.flex
                        , T.items_center
                        ]
                        [ S.buttonIcon FeatherIcons.check
                        , Html.text "Yes"
                        ]

            --
            , S.button
                [ E.onClick DenyAuthorisation
                , A.disabled isInProgress

                --
                , T.bg_base_400
                , T.items_center
                , T.ml_3
                , ifThenElse isInProgress T.hidden T.flex

                -- Dark mode
                ------------
                , T.dark__bg_base_600
                ]
                [ S.buttonIcon FeatherIcons.x
                , Html.text "No"
                ]
            ]

        -----------------------------------------
        -- Errors
        -----------------------------------------
        , case model.reLinkApp of
            Failure error ->
                Html.div
                    [ T.mt_5, T.text_red, T.text_sm ]
                    [ Html.text error ]

            _ ->
                Html.nothing

        -----------------------------------------
        -- As user
        -----------------------------------------
        , S.loggedInAs model
        ]


originLabel : Context -> List (Html Msg)
originLabel context =
    [ Html.text context.redirectTo.host
    , Html.text (Maybe.unwrap "" (String.fromInt >> (++) ":") context.redirectTo.port_)
    ]


appNameLabel : Context -> Maybe (List (Html Msg))
appNameLabel context =
    context.appFolder
        |> Maybe.andThen (String.split "/" >> List.getAt 1)
        |> Maybe.map (Html.text >> List.singleton)


rawResource : Result String String -> Html Msg
rawResource raw =
    Result.unwrap
        Resource.rawError
        (\permissions ->
            permissions
                |> Json.Print.prettyString { indent = 2, columns = 40 }
                |> Result.unwrap Resource.rawError Resource.raw
        )
        raw


warning : List (Html Msg) -> Html Msg
warning nodes =
    Html.div
        [ T.bg_marker_yellow_tint
        , T.flex
        , T.italic
        , T.items_center
        , T.max_w_md
        , T.mt_6
        , T.mx_auto
        , T.p_4
        , T.rounded_md
        , T.relative
        , T.shadow_sm
        , T.text_left
        , T.text_sm
        , T.text_marker_yellow_shade

        -- Dark mode
        ------------
        , T.dark__bg_marker_yellow_shade
        , T.dark__text_marker_yellow
        ]
        [ Icons.wrap
            [ T.align_middle
            , T.inline_block
            , T.mr_3
            , T.opacity_60
            ]
            (FeatherIcons.withSize 14 FeatherIcons.alertTriangle)
        , Html.span
            [ T.opacity_75 ]
            nodes
        ]
