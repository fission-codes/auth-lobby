module Radix exposing (..)

{-| Our top-level state.
-}

import Browser
import Browser.Navigation as Nav
import Page exposing (Page)
import RemoteData exposing (RemoteData)
import Url exposing (Url)



-- 🧩


type alias Model =
    { page : Page
    , navKey : Nav.Key
    , url : Url

    -----------------------------------------
    -- Remote Data
    -----------------------------------------
    , reCreateAccount : RemoteData String ()
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
