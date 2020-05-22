module Page exposing (..)

import Account.Creation.Context as Creation
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 🧩


type Page
    = Choose
    | CreateAccount Creation.Context
    | LinkAccount
    | LinkingApplication



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

        CreateAccount _ ->
            "/create-account"

        LinkAccount ->
            "/link-account"

        LinkingApplication ->
            "/"



-- ⚗️


urlParser : Url.Parser (Page -> a) a
urlParser =
    oneOf
        [ map Choose Url.top
        , map (CreateAccount Creation.default) (s "create-account")
        , map LinkAccount (s "link-account")
        ]
