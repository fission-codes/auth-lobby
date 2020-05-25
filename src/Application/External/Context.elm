module External.Context exposing (..)

import Browser.Navigation as Nav
import FeatherIcons
import Html exposing (Html, text)
import Icons
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..))
import Tailwind as T
import Url exposing (Url)
import Url.Builder
import Url.Parser as Url exposing (..)
import Url.Parser.Query as Query



-- 🧩


type alias Context =
    { did : String
    , redirectTo : Url
    }


type alias FailedState =
    { invalidRedirectTo : Bool
    , required : Bool
    }


type alias ParsedContext =
    RemoteData FailedState Context



-- 🏔


defaultFailedState : FailedState
defaultFailedState =
    { invalidRedirectTo = False
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
                    Success { did = c.did, redirectTo = redirectTo }

                Nothing ->
                    Failure { defaultFailedState | invalidRedirectTo = True }

        Nothing ->
            case url.query of
                Just "" ->
                    NotAsked

                Just _ ->
                    Failure defaultFailedState

                Nothing ->
                    NotAsked


redirectCommand :
    { ucan : Maybe String, username : String }
    -> ParsedContext
    -> Cmd msg
redirectCommand { ucan, username } remoteData =
    let
        defaultUrl =
            { protocol = Url.Https
            , host = username ++ ".fission.name"
            , port_ = Nothing
            , path = ""
            , query = Nothing
            , fragment = Nothing
            }

        maybeRedirectUrl =
            remoteData
                |> RemoteData.map .redirectTo
                |> RemoteData.toMaybe
    in
    maybeRedirectUrl
        |> Maybe.withDefault defaultUrl
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
                        (case ( ucan, maybeRedirectUrl ) of
                            ( Just ucantoo, Just _ ) ->
                                [ "ucan=" ++ Url.percentEncode ucantoo
                                , "username=" ++ Url.percentEncode username
                                ]

                            _ ->
                                []
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

        Failure { invalidRedirectTo, required } ->
            if invalidRedirectTo then
                warning
                    [ text "You provided an invalid"
                    , semibold " redirectTo "
                    , text "parameter, make sure it's a valid url."
                    ]

            else if required then
                warning
                    [ text "I'm missing some query parameters. You'll need the parameters "
                    , queryParams
                    ]

            else
                warning
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


warning : List (Html msg) -> Html msg
warning nodes =
    Html.div
        [ T.flex
        , T.items_center
        , T.max_w_sm
        , T.mt_8
        , T.mx_auto
        , T.neg_mb_3
        , T.text_red
        , T.text_sm
        ]
        [ FeatherIcons.alertTriangle
            |> FeatherIcons.withSize 18
            |> Icons.wrap [ T.flex_shrink_0 ]

        --
        , Html.div
            [ T.ml_2, T.pl_px ]
            nodes
        ]



-- ㊙️


queryStringParser =
    Query.map2
        (Maybe.map2
            (\d r ->
                { did = d
                , redirectTo = Url.fromString r
                }
            )
        )
        (Query.string "did")
        (Query.string "redirectTo")
