module Authorisation.Suggest.Resource exposing (FileSystemRoot(..), application, applicationFolder, custom, everything, fileSystemPath)

import FeatherIcons
import Html exposing (Html)
import Icons
import Radix exposing (..)
import Tailwind as T



-- 🧩


type FileSystemRoot
    = Private
    | Public



-- 🦉


everything : Html Msg
everything =
    resource
        [ resourceIcon FeatherIcons.alertTriangle
        , Html.text "Your entire Fission account"
        ]



-- 🛠


application : String -> Html Msg
application identifier =
    case identifier of
        "*" ->
            resource
                [ resourceIcon FeatherIcons.coffee
                , Html.span
                    []
                    [ Html.strong [] [ Html.text "All " ]
                    , Html.text "your Fission applications"
                    ]
                ]

        appDomain ->
            resource
                [ resourceIcon FeatherIcons.coffee
                , Html.span
                    []
                    [ Html.text "Your "
                    , Html.strong [] [ Html.text appDomain ]
                    , Html.text " Fission application"
                    ]
                ]


applicationFolder : String -> Html Msg
applicationFolder appName =
    resource
        [ resourceIcon FeatherIcons.package
        , Html.span
            []
            [ Html.text "The "
            , Html.strong [] [ Html.text appName ]
            , Html.text " application folder"
            ]
        ]


custom : String -> String -> Html Msg
custom key value =
    resource
        [ resourceIcon FeatherIcons.lock
        , Html.span
            []
            [ Html.text (key ++ ": ")
            , Html.strong [] [ Html.text value ]
            ]
        ]


fileSystemPath : FileSystemRoot -> String -> Html Msg
fileSystemPath root path =
    case path of
        "/" ->
            resource
                [ resourceIcon FeatherIcons.hardDrive
                , Html.span
                    []
                    [ Html.text "Your "
                    , Html.strong [] [ Html.text "entire " ]
                    , Html.text <|
                        case root of
                            Private ->
                                "private"

                            Public ->
                                "public"
                    , Html.text " file system"
                    ]
                ]

        _ ->
            resource
                [ resourceIcon FeatherIcons.hardDrive
                , Html.span
                    []
                    [ Html.strong [] [ Html.text path ]
                    , Html.text " in your "
                    , Html.text <|
                        case root of
                            Private ->
                                "private"

                            Public ->
                                "public"
                    , Html.text " file system"
                    ]
                ]



-- ㊙️


resource =
    resourceItem
        [ T.bg_white

        -- Dark mode
        ------------
        , T.dark__bg_darkness_below
        ]


resourceIcon icon =
    icon
        |> FeatherIcons.withSize 14
        |> Icons.wrap [ T.mr_3, T.opacity_60 ]


resourceItem additionalClasses nodes =
    Html.li
        (List.append
            [ T.border_b
            , T.border_black
            , T.border_opacity_05

            --
            , T.first__pt_px
            , T.first__rounded_t_md
            , T.last__border_transparent
            , T.last__rounded_b_md

            -- Dark mode
            ------------
            , T.dark__border_white
            , T.dark__border_opacity_025
            ]
            additionalClasses
        )
        [ Html.div
            [ T.flex
            , T.items_center
            , T.px_4
            , T.py_5
            ]
            nodes
        ]
