module Routing exposing (..)

import Browser
import Browser.Navigation as Nav
import Page exposing (Page)
import Ports
import Radix
import Return exposing (return)
import Url exposing (Url)



-- 📣


goToPage : Page -> Radix.Manager
goToPage page model =
    return
        { model | page = page }
        (case model.page of
            Page.LinkAccount _ ->
                -- When moving away from the link-account page,
                -- make sure to close the secure channel.
                Ports.closeSecureChannel ()

            _ ->
                Cmd.none
        )


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
