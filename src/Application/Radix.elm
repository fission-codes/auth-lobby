module Radix exposing (..)

{-| Our top-level state.
-}

import Browser
import Browser.Navigation as Nav
import Page exposing (Page)
import Url exposing (Url)



-- 🧩


type alias Model =
    { page : Page
    , navKey : Nav.Key
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
