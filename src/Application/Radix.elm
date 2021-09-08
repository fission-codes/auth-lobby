module Radix exposing (..)

{-| Our top-level state.

“Radix”
A root or point of origin.

-}

import Account.Creation.Context as Creation
import Account.Linking.Context as Linking
import Account.Linking.Exchange as Linking
import Authorisation.Suggest.Params as Suggest
import Authorisation.Suggest.Progress exposing (ProgressUpdate, TimedProgress)
import Browser
import Browser.Navigation as Nav
import Debouncer.Messages as Debouncer exposing (Debouncer)
import External.Context as External
import Flow exposing (Flow)
import Http
import Json.Decode as Json
import Page exposing (Page)
import RemoteData exposing (RemoteData)
import Theme exposing (Theme)
import Time
import Url exposing (Url)



-- 🧩


type alias Model =
    { apiDomain : String
    , dataRootDomain : String
    , externalContext : External.ParsedContext
    , page : Page
    , navKey : Nav.Key
    , theme : RemoteData String Theme
    , url : Url
    , usedUsername : Maybe String
    , version : String

    -----------------------------------------
    -- Debouncers
    -----------------------------------------
    , ionDidValidDebouncer : Debouncer Msg
    , usernameAvailabilityDebouncer : Debouncer Msg

    -----------------------------------------
    -- Remote Data & Flows
    -----------------------------------------
    , reCreateAccount : RemoteData String ()
    , reLinkApp : Flow String TimedProgress
    }



-- 📣


type Msg
    = Bypassed
      -----------------------------------------
      -- Authorisation
      -----------------------------------------
    | AllowAuthorisation Time.Posix
    | DenyAuthorisation
    | GotLinkAppError String
    | GotLinkAppParams Suggest.Params
    | GotLinkAppProgress ProgressUpdate
      -----------------------------------------
      -- Create
      -----------------------------------------
    | CheckIfIonDidIsValid
    | CheckIfUsernameIsAvailable
    | CreateAccount Creation.Context
    | GotCreateAccountFailure String
    | GotCreateAccountSuccess
    | GotCreateEmailInput String
    | GotCreateIonDidInput String
    | GotCreateIonDidValid { valid : Bool }
    | GotCreateIonKeyInput String
    | GotCreateUsernameInput String
    | GotUsernameAvailability { available : Bool, valid : Bool }
    | SkipLinkDuringSetup
      -----------------------------------------
      -- Debouncers
      -----------------------------------------
    | IonDidValidDebouncerMsg (Debouncer.Msg Msg)
    | UsernameAvailabilityDebouncerMsg (Debouncer.Msg Msg)
      -----------------------------------------
      -- Linking
      -----------------------------------------
    | CancelLink { onBothSides : Bool }
    | GotLinked { username : String }
    | GotLinkExchangeError String
    | GotLinkUsernameInput String
    | LinkAccount Linking.Context
    | SendLinkingUcan Linking.Exchange
      -----------------------------------------
      -- Routing
      -----------------------------------------
    | GoToPage Page
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
      -----------------------------------------
      -- Channel
      -----------------------------------------
    | GotInvalidRootDid
    | GotChannelMessage Json.Value
      -----------------------------------------
      -- 🧿 Other things
      -----------------------------------------
    | CopyToClipboard String
    | GetCurrentTime (Time.Posix -> Msg)
    | GotThemeViaHttp (Result Http.Error String)
    | GotThemeViaIpfs (Result Http.Error String)
    | Leave


type alias Manager =
    Model -> ( Model, Cmd Msg )
