module Routing exposing (..)

import Browser
import Browser.Navigation as Nav
import Page
import Radix
import Return exposing (return)
import Url exposing (Url)



-- 📣


urlChanged : Url -> Radix.Manager
urlChanged url model =
    Return.singleton { model | page = Page.fromUrl url, url = url }


urlRequested : Browser.UrlRequest -> Radix.Manager
urlRequested request model =
    case request of
        Browser.Internal url ->
            return model (Nav.pushUrl model.navKey <| Url.toString url)

        Browser.External href ->
            return model (Nav.load href)
