module Routing exposing (..)

import Browser
import Radix
import Return
import Url exposing (Url)



-- 📣


urlChanged : Url -> Radix.Manager
urlChanged url model =
    Return.singleton { model | url = url }


urlRequested : Browser.UrlRequest -> Radix.Manager
urlRequested request =
    -- TODO
    Return.singleton
