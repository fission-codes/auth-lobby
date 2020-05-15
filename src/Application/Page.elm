module Page exposing (..)

import Account.Creation.Context as Creation
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 🧩


type Page
    = Choose
    | Create Creation.Context
    | Link



-- 🛠


fromUrl : Url -> Page
fromUrl url =
    url
        |> Url.parse urlParser
        |> Maybe.withDefault Choose


toPath : Page -> String
toPath page =
    case page of
        Choose ->
            "/"

        Create _ ->
            "/create-account"

        Link ->
            "/link-account"



-- ⚗️


urlParser : Url.Parser (Page -> a) a
urlParser =
    oneOf
        [ map Choose Url.top
        , map (Create Creation.default) (s "create-account")
        , map Link (s "link-account")
        ]
