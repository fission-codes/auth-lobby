module Routing exposing (..)

import Browser
import Browser.Navigation as Nav
import Page exposing (Page)
import Radix
import Return exposing (return)
import Url exposing (Url)



-- 📣


goToPage : Page -> Radix.Manager
goToPage page model =
    Return.singleton { model | page = page }


urlChanged : Url -> Radix.Manager
urlChanged url model =
    Return.singleton { model | url = url }


urlRequested : Browser.UrlRequest -> Radix.Manager
urlRequested request model =
    case request of
        Browser.Internal url ->
            return model (Nav.pushUrl model.navKey <| Url.toString url)

        Browser.External href ->
            return model (Nav.load href)
