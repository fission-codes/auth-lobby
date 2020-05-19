module External.Context exposing (Context, extractFromUrl)

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



-- ㊙️


queryStringParser =
    Url.map
        (\redirectTo -> { redirectTo = Maybe.andThen Url.fromString redirectTo })
        (Url.query <| Query.string "redirectTo")
