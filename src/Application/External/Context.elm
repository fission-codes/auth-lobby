module External.Context exposing (Context, extractFromUrl, redirectCmd)

import Browser.Navigation as Nav
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
    Url.parse queryStringParser { url | path = "" }


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



-- ㊙️


queryStringParser =
    Url.map
        (\redirectTo -> { redirectTo = Maybe.andThen Url.fromString redirectTo })
        (Url.query <| Query.string "redirectTo")
