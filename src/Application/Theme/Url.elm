module Theme.Url exposing (..)

import Http
import Maybe.Extra as Maybe
import Radix exposing (Msg(..))
import Url exposing (Url)
import Url.Parser as Url exposing (..)
import Url.Parser.Query as Query


extractPointer : Url -> Maybe String
extractPointer url =
    { url | path = "" }
        |> Url.parse (Url.query pointerQueryStringParser)
        |> Maybe.join


fetch : String -> String -> Cmd Msg
fetch apiDomain pointer =
    if String.contains "/" pointer then
        Http.get
            { url = pointer
            , expect = Http.expectString GotThemeViaHttp
            }

    else
        let
            domain =
                if apiDomain == "runfission.net" then
                    apiDomain

                else
                    "runfission.com"
        in
        -- IPFS
        Http.get
            { url = "https://ipfs." ++ domain ++ "/ipfs/" ++ pointer
            , expect = Http.expectString GotThemeViaIpfs
            }


pointerQueryStringParser =
    Query.string "theme"
