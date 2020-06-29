module Radix exposing (..)

{-| Our top-level state.

“Radix”
A root or point of origin.

-}

import Account.Creation.Context as Creation
import Account.Linking.Context as Linking
import Account.Linking.Exchange as Linking
import Browser
import Browser.Navigation as Nav
import Debouncer.Messages as Debouncer exposing (Debouncer)
import External.Context as External
import Json.Decode as Json
import Page exposing (Page)
import RemoteData exposing (RemoteData)
import Url exposing (Url)



-- 🧩


type alias Model =
    { dataRootDomain : String
    , externalContext : External.ParsedContext
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
      -----------------------------------------
      -- Authorisation
      -----------------------------------------
    | AllowAuthorisation
    | DenyAuthorisation
    | GotUcanForApplication { ucan : String }
      -----------------------------------------
      -- Create
      -----------------------------------------
    | CheckIfUsernameIsAvailable
    | CreateAccount Creation.Context
    | GotCreateAccountFailure String
    | GotCreateAccountSuccess
    | GotCreateEmailInput String
    | GotCreateUsernameInput String
    | GotUsernameAvailability { available : Bool, valid : Bool }
      -----------------------------------------
      -- Debouncers
      -----------------------------------------
    | UsernameAvailabilityDebouncerMsg (Debouncer.Msg Msg)
      -----------------------------------------
      -- Linking
      -----------------------------------------
    | CancelLink
    | GotLinked { username : String }
    | GotLinkUsernameInput String
    | LinkAccount Linking.Context
    | SendLinkingUcan Linking.Exchange
    | StartLinkingExchange Linking.Context ( String, String )
      -----------------------------------------
      -- Routing
      -----------------------------------------
    | GoToPage Page
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
      -----------------------------------------
      -- Secure Channel
      -----------------------------------------
    | GotInvalidRootDid
    | GotSecureChannelMessage Json.Value
    | SecureChannelOpened
      -----------------------------------------
      -- 🧿 Other things
      -----------------------------------------
    | CopyToClipboard String


type alias Manager =
    Model -> ( Model, Cmd Msg )
