module External.Context exposing (..)

import Base64
import Browser.Navigation as Nav
import Common exposing (ifThenElse)
import Dict exposing (Dict)
import FeatherIcons
import Html exposing (Html, text)
import Icons
import Json.Decode
import Json.Encode
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..))
import Result.Extra as Result
import Styling as S
import Tailwind as T
import Url exposing (Url)
import Url.Builder
import Url.Parser as Url exposing (..)
import Url.Parser.Query as Query



-- 🧩


type alias Context =
    { app : Maybe String
    , didExchange : String
    , didWrite : String
    , lifetimeInSeconds : Int
    , newUser : Maybe Bool
    , privatePaths : List String
    , publicPaths : List String
    , redirectTo : Url
    }


type alias FailedState =
    { invalidRedirectTo : Bool
    , missingResource : Bool
    , required : Bool
    }


type alias ParsedContext =
    RemoteData FailedState Context



-- 🏔


defaultFailedState : FailedState
defaultFailedState =
    { invalidRedirectTo = False
    , missingResource = False
    , required = False
    }



-- 🛠


extractFromUrl : Url -> ParsedContext
extractFromUrl url =
    let
        maybeContext =
            { url | path = "" }
                |> Url.parse (Url.query queryStringParser)
                |> Maybe.join
    in
    case maybeContext of
        Just c ->
            case c.redirectTo of
                Just redirectTo ->
                    Success
                        { app = c.app
                        , didExchange = c.didExchange
                        , didWrite = c.didWrite
                        , lifetimeInSeconds = c.lifetimeInSeconds
                        , newUser = c.newUser
                        , privatePaths = c.privatePaths
                        , publicPaths = c.publicPaths
                        , redirectTo = redirectTo
                        }

                Nothing ->
                    Failure
                        { defaultFailedState | invalidRedirectTo = True }

        Nothing ->
            case url.query of
                Just "" ->
                    NotAsked

                Just query ->
                    if String.contains "&username=" query then
                        NotAsked

                    else if String.contains "theme=" query then
                        NotAsked

                    else
                        Failure defaultFailedState

                Nothing ->
                    NotAsked


redirectCommand :
    Result
        String
        { newUser : Bool
        , readKeys : Dict String String
        , ucans : List String
        , username : String
        }
    -> ParsedContext
    -> Cmd msg
redirectCommand result remoteData =
    let
        defaultUrl =
            { protocol = Url.Https
            , host = "fission.codes"
            , port_ = Nothing
            , path = ""
            , query = Nothing
            , fragment = Nothing
            }

        redirectUrl =
            remoteData
                |> RemoteData.map .redirectTo
                |> RemoteData.withDefault defaultUrl
    in
    redirectUrl
        |> (\u ->
                case u.query of
                    Just "" ->
                        { u | query = Nothing }

                    _ ->
                        u
           )
        |> (\u ->
                u.query
                    |> Maybe.map (String.split "&")
                    |> Maybe.withDefault []
                    |> List.append
                        (case result of
                            Ok { newUser, readKeys, ucans, username } ->
                                let
                                    keys =
                                        readKeys
                                            |> Json.Encode.dict identity Json.Encode.string
                                            |> Json.Encode.encode 0
                                            |> (\s -> Maybe.withDefault s <| Base64.fromString s)
                                in
                                [ "newUser=" ++ ifThenElse newUser "t" "f"
                                , "readKeys=" ++ Url.percentEncode keys
                                , "ucans=" ++ Url.percentEncode (String.join "," ucans)
                                , "username=" ++ Url.percentEncode username
                                ]

                            Err cancellationReason ->
                                [ "cancelled=" ++ Url.percentEncode cancellationReason
                                ]
                        )
                    |> String.join "&"
                    |> (\q -> { u | query = Just q })
           )
        |> Url.toString
        |> Nav.load



-- 🖼


note : ParsedContext -> Html msg
note remoteData =
    case remoteData of
        Loading ->
            text ""

        Failure { invalidRedirectTo, missingResource, required } ->
            if missingResource then
                S.warning
                    [ text "I'm missing a resource. "
                    , text "I need one of the following:"
                    , semibold "appFolder"
                    , text ", "
                    , semibold "privatePath"
                    , text " or "
                    , semibold "publicPath"
                    , text "."
                    ]

            else if invalidRedirectTo then
                S.warning
                    [ text "You provided an invalid"
                    , semibold " redirectTo "
                    , text "parameter, make sure it's a valid url."
                    ]

            else if required then
                S.warning
                    [ text "I'm missing some query parameters. You'll need the parameters "
                    , queryParams
                    ]

            else
                S.warning
                    [ text "You provided some query params, but they didn't check out."
                    , text " Maybe you're missing one?"
                    , text " The correct ones are "
                    , queryParams
                    ]

        NotAsked ->
            text ""

        Success context ->
            text ""


queryParams : Html msg
queryParams =
    Html.span
        []
        [ semibold "didExchange"
        , text ", "
        , semibold "didWrite"
        , text " and "
        , semibold "redirectTo"
        , text ", where "
        , semibold "redirectTo"
        , text " is a valid url."
        ]


semibold : String -> Html msg
semibold t =
    Html.span
        [ T.antialiased
        , T.font_bold
        , T.inline_block
        , T.mx_1
        , T.underline
        , T.underline_thick
        ]
        [ text t ]



-- ㊙️


queryStringParser =
    Query.map8
        (\app pri pub lif new ->
            Maybe.map3
                (\didExchange didWrite red ->
                    { app = app
                    , didExchange = didExchange
                    , didWrite = didWrite
                    , lifetimeInSeconds = Maybe.withDefault (60 * 60 * 24 * 30) lif
                    , newUser = Maybe.map (String.toLower >> (==) "t") new
                    , privatePaths = pri
                    , publicPaths = pub
                    , redirectTo = Url.fromString red
                    }
                )
        )
        -- Optional, pt. 1
        (Query.string "appFolder")
        (Query.custom "privatePath" identity)
        (Query.custom "publicPath" identity)
        -- Optional, pt. 2
        (Query.int "lifetimeInSeconds")
        (Query.string "newUser")
        -- Required
        (Query.string "didExchange")
        (Query.string "didWrite")
        (Query.string "redirectTo")
