module Radix exposing (..)

{-| Our top-level state.
-}

import Browser
import Browser.Navigation as Nav
import Screens exposing (Screen)
import Url exposing (Url)



-- 🧩


type alias Model =
    { navKey : Nav.Key
    , screen : Screen
    , url : Url
    }



-- 📣


type Msg
    = Bypassed
      -----------------------------------------
      -- URL
      -----------------------------------------
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest


type alias Manager =
    Model -> ( Model, Cmd Msg )
