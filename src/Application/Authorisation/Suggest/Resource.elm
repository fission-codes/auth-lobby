module Authorisation.Suggest.Resource exposing (FileSystemRoot(..), application, applicationFolder, custom, everything, fileSystemPath, raw, rawError, sharedSection)

import FeatherIcons
import Html exposing (Html)
import Icons
import Json.Print
import Radix exposing (..)
import Styling as S
import Tailwind as T



-- 🧩


type FileSystemRoot
    = Private
    | Public



-- 🦉


everything : Html Msg
everything =
    S.resource
        { icon = FeatherIcons.alertTriangle
        , label = Html.text "Your entire Fission account"
        }



-- 🛠


application : String -> Html Msg
application identifier =
    case identifier of
        "*" ->
            S.resource
                { icon = FeatherIcons.coffee
                , label =
                    Html.span
                        []
                        [ Html.strong [] [ Html.text "All " ]
                        , Html.text "your Fission applications"
                        ]
                }

        appDomain ->
            S.resource
                { icon = FeatherIcons.coffee
                , label =
                    Html.span
                        []
                        [ Html.text "Your "
                        , Html.strong [] [ Html.text appDomain ]
                        , Html.text " Fission application"
                        ]
                }


applicationFolder : String -> Html Msg
applicationFolder appName =
    S.resource
        { icon = FeatherIcons.package
        , label =
            Html.span
                []
                [ Html.text "The "
                , Html.strong [] [ Html.text appName ]
                , Html.text " application folder"
                ]
        }


custom : String -> String -> Html Msg
custom key value =
    S.resource
        { icon = FeatherIcons.lock
        , label =
            Html.span
                []
                [ Html.text (key ++ ": ")
                , Html.strong [] [ Html.text value ]
                ]
        }


raw : String -> Html Msg
raw permissions =
    rawResource
        [ rawLabel
            [ S.resourceIcon FeatherIcons.lock
            , Html.text "Additional resources requested"
            ]
        , Html.pre
            []
            [ Html.text permissions ]
        ]


rawError : Html Msg
rawError =
    S.resource
        { icon = FeatherIcons.alertTriangle
        , label = Html.text "Invalid resource request. This request will be ignored."
        }


fileSystemPath : FileSystemRoot -> String -> Html Msg
fileSystemPath root path =
    case path of
        "/" ->
            S.resource
                { icon = FeatherIcons.hardDrive
                , label =
                    Html.span
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
                }

        _ ->
            S.resource
                { icon = FeatherIcons.hardDrive
                , label =
                    Html.span
                        []
                        [ Html.strong [] [ Html.text (removeLeadingSlash path) ]
                        , Html.text " in your "
                        , Html.text <|
                            case root of
                                Private ->
                                    "private"

                                Public ->
                                    "public"
                        , Html.text " file system"
                        ]
                }


sharedSection =
    S.resource
        { icon = FeatherIcons.share2
        , label = Html.text "Ability to share the private files the app can access"
        }



-- ㊙️


removeLeadingSlash string =
    if String.startsWith "/" string then
        String.dropLeft 1 string

    else
        string


rawLabel nodes =
    Html.div
        [ T.flex
        , T.items_center
        ]
        nodes


rawResource nodes =
    S.resource_
        [ Html.div
            [ T.flex
            , T.flex_col
            , T.justify_center
            , T.overflow_x_auto
            , T.space_y_3
            , T.space_x_6
            , T.px_4
            , T.py_5
            ]
            nodes
        ]
