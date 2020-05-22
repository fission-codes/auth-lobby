module Radix exposing (..)

{-| Our top-level state.

“Radix”
A root or point of origin.

-}

import Account.Creation.Context as Create
import Browser
import Browser.Navigation as Nav
import Debouncer.Messages as Debouncer exposing (Debouncer)
import External.Context as External
import Page exposing (Page)
import RemoteData exposing (RemoteData)
import Url exposing (Url)



-- 🧩


type alias Model =
    { externalContext : RemoteData () External.Context
    , page : Page
    , navKey : Nav.Key
    , url : Url
    , usedUsername : Maybe String

    -----------------------------------------
    -- Debouncers
    -----------------------------------------
    , usernameAvailabilityDebouncer : Debouncer Msg

    -----------------------------------------
    -- Remote Data
    -----------------------------------------
    , reCreateAccount : RemoteData String ()
    }



-- 📣


type Msg
    = Bypassed
    | GotUcanForApplication { ucan : String }
      -----------------------------------------
      -- Create
      -----------------------------------------
    | CheckIfUsernameIsAvailable
    | CreateAccount Create.Context
    | GotCreateAccountFailure String
    | GotCreateAccountSuccess { ucan : Maybe String }
    | GotCreateEmailInput String
    | GotCreateUsernameInput String
    | GotUsernameAvailability { available : Bool, valid : Bool }
      -----------------------------------------
      -- Debouncers
      -----------------------------------------
    | UsernameAvailabilityDebouncerMsg (Debouncer.Msg Msg)
      -----------------------------------------
      -- URL
      -----------------------------------------
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest


type alias Manager =
    Model -> ( Model, Cmd Msg )
