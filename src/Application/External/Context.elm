module External.Context exposing (Context, extractFromUrl, note, redirectCommand)

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
    , redirectTo : Maybe Url
    }



-- 🛠


extractFromUrl : Url -> RemoteData () Context
extractFromUrl url =
    let
        maybeContext =
            { url | path = "" }
                |> Url.parse (Url.query queryStringParser)
                |> Maybe.join
    in
    case maybeContext of
        Just context ->
            Success context

        Nothing ->
            case url.query of
                Just "" ->
                    NotAsked

                Just _ ->
                    Failure ()

                Nothing ->
                    NotAsked


redirectCommand : { ucan : Maybe String, username : String } -> RemoteData () Context -> Cmd msg
redirectCommand { ucan, username } remoteData =
    let
        defaultUrl =
            { protocol = Url.Https
            , host = username ++ ".fission.app"
            , port_ = Nothing
            , path = ""
            , query = Nothing
            , fragment = Nothing
            }

        maybeRedirectUrl =
            remoteData
                |> RemoteData.map .redirectTo
                |> RemoteData.toMaybe
                |> Maybe.join
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


note : RemoteData () Context -> Html msg
note remoteData =
    case remoteData of
        Loading ->
            text ""

        Failure () ->
            [ text "You provided some query params, but they didn't check out."
            , text " Maybe you're missing one?"
            , text " The correct ones are "
            , semibold "did"
            , text " and "
            , semibold "redirectTo"
            , text ", where "
            , semibold "redirectTo"
            , text " is a valid url."
            ]
                |> warning

        NotAsked ->
            text ""

        Success context ->
            noteForSuccess context


noteForSuccess : Context -> Html msg
noteForSuccess { redirectTo } =
    case redirectTo of
        Just _ ->
            text ""

        Nothing ->
            warning
                [ text "You provided an invalid"
                , semibold " redirectTo "
                , text "parameter, make sure it's a valid url."
                ]


semibold : String -> Html msg
semibold t =
    Html.span [ T.font_semibold ] [ text t ]


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
