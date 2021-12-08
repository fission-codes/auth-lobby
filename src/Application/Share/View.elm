module Share.View exposing (..)

import Branding
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Maybe.Extra as Maybe
import Radix exposing (Model, Msg(..))
import Share.Accept.Context as Accept
import Share.Accept.Progress exposing (Progress(..))
import Styling as S
import Tailwind as T
import Url.Builder as Url


accept : Accept.Context -> Model -> Html Msg
accept context model =
    Html.div
        [ T.text_center ]
        [ Branding.logo model

        -----------------------------------------
        -- Progress
        -----------------------------------------
        , Html.div
            [ T.mt_8 ]
            [ case context.progress of
                Failed err ->
                    Html.div
                        [ T.flex
                        , T.items_center
                        , T.justify_center
                        , T.max_w_sm
                        , T.mx_auto
                        , T.text_red
                        , T.text_sm
                        ]
                        [ S.buttonIcon FeatherIcons.alertCircle
                        , Html.text err
                        ]

                --
                Preparing ->
                    loading "Loading your filesystem"

                Loading ->
                    loading "Loading the shared data"

                Loaded list ->
                    acceptForm context list

                Accepting ->
                    loading "Copying links to shared data"

                Publishing ->
                    loading "Updating data root"

                Published ->
                    published model context
            ]

        -----------------------------------------
        -- As user
        -----------------------------------------
        , S.loggedInAs model
        ]


acceptForm context list =
    Html.div
        []
        [ Html.p
            []
            [ Html.strong [] [ Html.text context.sharedBy ]
            , Html.text " has shared some files with you."
            ]

        -----------------------------------------
        -- Shared items
        -----------------------------------------
        , S.resourceList
            (List.map
                (\i ->
                    S.resource
                        { icon =
                            if i.isFile then
                                FeatherIcons.file

                            else
                                FeatherIcons.folder
                        , label =
                            Html.text i.name
                        }
                )
                list
            )

        -----------------------------------------
        -- Buttons
        -----------------------------------------
        , Html.div
            [ T.flex
            , T.justify_center
            , T.mt_8
            ]
            [ S.button
                [ E.onClick AcceptShare

                --
                , T.bg_purple
                , T.flex
                , T.items_center
                ]
                [ S.buttonIcon FeatherIcons.hardDrive
                , Html.text "Add to filesystem"
                ]
            ]
        ]


loading text =
    Html.div
        [ T.inline_flex ]
        [ S.progress text ]


published model context =
    Html.div
        []
        [ Html.p
            []
            [ Html.text "The items have been added to your filesystem." ]

        --
        , Html.p
            [ T.italic
            , T.mt_6
            , T.opacity_60
            , T.text_sm
            ]
            [ Html.text "These items will be updated when "
            , Html.strong [] [ Html.text context.sharedBy ]
            , Html.text " makes changes to them."
            , Html.br [] []
            , Html.text "You can find them in your "
            , Html.span
                [ A.style "font-size" "13px"
                , T.font_mono
                ]
                [ Html.text "private/Shared with me/"
                , Html.text context.sharedBy
                , Html.text "/"
                ]
            , Html.text " folder."
            ]

        -----------------------------------------
        -- Buttons
        -----------------------------------------
        , let
            driveHost =
                if model.url.host == "localhost" then
                    "http://localhost:8000"

                else if model.apiDomain == "runfission.net" then
                    "https://drive.runfission.net"

                else
                    "https://drive.fission.codes"

            driveUrl =
                Url.crossOrigin
                    driveHost
                    [ "#"
                    , Maybe.withDefault "" model.usedUsername
                    , "Shared with me"
                    , context.sharedBy
                    , ""
                    ]
                    []
          in
          Html.div
            [ T.flex
            , T.justify_center
            , T.mt_8
            ]
            [ S.buttonLink
                [ A.href driveUrl

                --
                , T.bg_purple
                , T.flex
                , T.items_center
                ]
                [ S.buttonIcon FeatherIcons.hardDrive
                , Html.text "Open in Drive"
                ]
            ]
        ]
