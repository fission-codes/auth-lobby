module External.Context exposing (Context, extractFromUrl, redirectCmd, redirectToNote)

import Browser.Navigation as Nav
import FeatherIcons
import Html exposing (Html)
import Maybe.Extra as Maybe
import Tailwind as T
import Url exposing (Url)
import Url.Parser as Url exposing (..)
import Url.Parser.Query as Query



-- 🧩


type alias Context =
    { redirectTo : Maybe Url
    }



-- 🛠


extractFromUrl : Url -> Maybe Context
extractFromUrl url =
    { url | path = "" }
        |> Url.parse queryStringParser
        |> Maybe.join


redirectCmd : String -> Context -> Maybe (Cmd msg)
redirectCmd username context =
    let
        kv =
            "username=" ++ username
    in
    Maybe.map
        (\redirectTo ->
            redirectTo.query
                |> Maybe.map
                    (\q ->
                        if q == "" then
                            kv

                        else
                            q ++ "&" ++ kv
                    )
                |> Maybe.withDefault kv
                |> (\q -> { redirectTo | query = Just q })
                |> Url.toString
                |> Nav.load
        )
        context.redirectTo



-- 🖼


redirectToNote : Context -> Html msg
redirectToNote { redirectTo } =
    case redirectTo of
        Just _ ->
            Html.text ""

        Nothing ->
            Html.div
                [ T.flex
                , T.items_center
                , T.mt_6
                , T.text_red
                , T.text_sm
                ]
                [ FeatherIcons.alertTriangle
                    |> FeatherIcons.withSize 18
                    |> FeatherIcons.toHtml []

                --
                , Html.div
                    [ T.ml_1 ]
                    [ Html.text "You provided an invalid"
                    , Html.span [ T.font_semibold ] [ Html.text " redirectTo " ]
                    , Html.text "parameter, make sure it's a valid url."
                    ]
                ]



-- ㊙️


queryStringParser =
    Url.map
        (Maybe.map <| \redirectTo -> { redirectTo = Url.fromString redirectTo })
        (Url.query <| Query.string "redirectTo")
