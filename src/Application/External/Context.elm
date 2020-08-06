module External.Context exposing (..)

import Browser.Navigation as Nav
import Common exposing (ifThenElse)
import Dict exposing (Dict)
import FeatherIcons
import Html exposing (Html, text)
import Icons
import Json.Decode
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
    { did : String
    , lifetimeInSeconds : Int
    , newUser : Maybe Bool
    , redirectTo : Url
    , resource : Resource
    }


type alias FailedState =
    { invalidRedirectTo : Bool
    , invalidResource : Bool
    , required : Bool
    }


type alias ParsedContext =
    RemoteData FailedState Context


type Resource
    = Everything
    | Resources (Dict String String)



-- 🏔


defaultFailedState : FailedState
defaultFailedState =
    { invalidRedirectTo = False
    , invalidResource = False
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
            let
                decodedResource =
                    if c.resource == "*" then
                        Ok Everything

                    else
                        c.resource
                            |> Json.Decode.decodeString resourceDecoder
                            |> Result.map Resources
            in
            case ( c.redirectTo, decodedResource ) of
                ( Just redirectTo, Ok resource ) ->
                    Success
                        { did = c.did
                        , lifetimeInSeconds = c.lifetimeInSeconds
                        , newUser = c.newUser
                        , resource = resource
                        , redirectTo = redirectTo
                        }

                ( Nothing, _ ) ->
                    Failure
                        { defaultFailedState | invalidRedirectTo = True }

                ( _, Err _ ) ->
                    Failure
                        { defaultFailedState | invalidResource = True }

        Nothing ->
            case url.query of
                Just "" ->
                    NotAsked

                Just _ ->
                    Failure defaultFailedState

                Nothing ->
                    NotAsked


redirectCommand :
    Result String
        { newUser : Bool
        , ucan : String
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
                            Ok { newUser, ucan, username } ->
                                [ "newUser=" ++ ifThenElse newUser "t" "f"
                                , "ucan=" ++ Url.percentEncode ucan
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

        Failure { invalidRedirectTo, invalidResource, required } ->
            if invalidRedirectTo then
                S.warning
                    [ text "You provided an invalid"
                    , semibold " redirectTo "
                    , text "parameter, make sure it's a valid url."
                    ]

            else if invalidResource then
                S.warning
                    [ text "You provided an invalid"
                    , semibold " resource "
                    , text "parameter, make sure it's a valid object encoded as a json string (eg. `{\"resource\":\"name\"}`)."
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
        [ semibold "did"
        , text " and "
        , semibold "redirectTo"
        , text ", where "
        , semibold "redirectTo"
        , text " is a valid url."
        ]


semibold : String -> Html msg
semibold t =
    Html.span
        [ T.font_semibold
        , T.inline_block
        , T.mx_1
        , T.underline
        , T.underline_thick
        ]
        [ text t ]



-- ㊙️


queryStringParser =
    Query.map5
        (\lif new res ->
            Maybe.map2
                (\did red ->
                    { did = did
                    , lifetimeInSeconds = Maybe.withDefault (60 * 60 * 24 * 30) lif
                    , newUser = Maybe.map (String.toLower >> (==) "t") new
                    , redirectTo = Url.fromString red
                    , resource = Maybe.withDefault "*" res
                    }
                )
        )
        -- Optional
        (Query.int "lifetimeInSeconds")
        (Query.string "newUser")
        (Query.string "resource")
        -- Required
        (Query.string "did")
        (Query.string "redirectTo")


resourceDecoder : Json.Decode.Decoder (Dict String String)
resourceDecoder =
    Json.Decode.dict Json.Decode.string
