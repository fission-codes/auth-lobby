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
import Semver
import Styling as S
import Tailwind as T
import Url exposing (Url)
import Url.Builder
import Url.Parser as Url exposing (..)
import Url.Parser.Query as Query



-- 🧩


type alias Context =
    { appFolder : Maybe String
    , didExchange : String
    , didWrite : String
    , lifetimeInSeconds : Int
    , newUser : Maybe Bool
    , privatePaths : List String
    , publicPaths : List String
    , redirectTo : Url
    , redirectToProtocol : String
    , sharedRepo : Bool
    , web : List String

    -- TODO: Remove backwards compatibility
    , oldFlow : Bool
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
            case ( c.redirectTo, c.redirectToProtocol ) of
                ( Just redirectTo, Just redirectToProtocol ) ->
                    Success
                        { appFolder = c.appFolder
                        , didExchange = c.didExchange
                        , didWrite = c.didWrite
                        , lifetimeInSeconds = c.lifetimeInSeconds
                        , newUser = c.newUser
                        , privatePaths = c.privatePaths
                        , publicPaths = c.publicPaths
                        , redirectTo = redirectTo
                        , redirectToProtocol = redirectToProtocol
                        , sharedRepo = c.sharedRepo
                        , web = c.web

                        -- TODO: Remove backwards compatibility
                        , oldFlow = c.oldFlow
                        }

                _ ->
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
    Result String (List ( String, String ))
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

        redirectProtocol =
            remoteData
                |> RemoteData.map .redirectToProtocol
                |> RemoteData.withDefault "https"

        params =
            case result of
                Ok dict ->
                    dict

                Err cancellationReason ->
                    [ ( "cancelled", cancellationReason ) ]
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
                        (List.map
                            (\( a, b ) -> Url.percentEncode a ++ "=" ++ Url.percentEncode b)
                            params
                        )
                    |> String.join "&"
                    |> (\q -> { u | query = Just q })
           )
        |> Url.toString
        |> String.dropLeft 8
        |> String.append redirectProtocol
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


apply : Query.Parser a -> Query.Parser (a -> b) -> Query.Parser b
apply argParser funcParser =
    Query.map2 (<|) funcParser argParser


queryStringParser =
    Query.map
        (\fol app pri pub lif new sdk sha ->
            Maybe.map3
                (\didExchange didWrite red ->
                    let
                        protocolEndIndex =
                            Maybe.or
                                (Maybe.map ((+) 4) <| List.head <| String.indices ":///" red)
                                (Maybe.map ((+) 3) <| List.head <| String.indices "://" red)

                        protocol =
                            Maybe.map
                                (\i -> String.left i red)
                                protocolEndIndex

                        redirectTo =
                            Maybe.map
                                -- Temporary solution for unsupported protocols
                                (\i ->
                                    red
                                        |> String.dropLeft i
                                        |> String.append "https://"
                                )
                                protocolEndIndex
                    in
                    { appFolder = fol
                    , didExchange = didExchange
                    , didWrite = didWrite
                    , lifetimeInSeconds = Maybe.withDefault (60 * 60 * 24 * 30) lif
                    , newUser = Maybe.map (String.toLower >> (==) "t") new
                    , privatePaths = confirmPaths pri
                    , publicPaths = confirmPaths pub
                    , redirectTo = Maybe.andThen Url.fromString redirectTo
                    , redirectToProtocol = protocol
                    , sharedRepo = Maybe.unwrap False ((==) "t") sha
                    , web = app

                    -- TODO: Remove backwards compatibility
                    , oldFlow =
                        sdk
                            |> Maybe.andThen Semver.parse
                            |> Maybe.map (\version -> Semver.lessThan version newFlowSdkVersion)
                            |> Maybe.withDefault True
                    }
                )
        )
        -- Optional, pt. 1
        (Query.string "appFolder")
        |> apply (Query.custom "app" identity)
        |> apply (Query.custom "privatePath" identity)
        |> apply (Query.custom "publicPath" identity)
        -- Optional, pt. 2
        |> apply (Query.int "lifetimeInSeconds")
        |> apply (Query.string "newUser")
        |> apply (Query.string "sdk")
        |> apply (Query.string "sharedRepo")
        -- Required
        |> apply (Query.string "didExchange")
        |> apply (Query.string "didWrite")
        |> apply (Query.string "redirectTo")


confirmPaths : List String -> List String
confirmPaths =
    List.filterMap
        (\p ->
            let
                path =
                    String.trim p
            in
            if String.isEmpty path then
                Nothing

            else
                Just path
        )


newFlowSdkVersion =
    Semver.version 0 22 0 [] []
