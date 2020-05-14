module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Radix exposing (Model, Msg(..))
import Return
import Routing
import Url exposing (Url)
import View



-- ⛩


type alias Flags =
    { hasCreatedAccount : Bool }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        , view = view
        }



-- 🌱


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    Return.singleton
        { hasCreatedAccount = flags.hasCreatedAccount
        , navKey = navKey
        , url = url
        }



-- 📣


update : Msg -> Radix.Manager
update msg =
    case msg of
        Bypassed ->
            Return.singleton

        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged a ->
            Routing.urlChanged a

        UrlRequested a ->
            Routing.urlRequested a



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = "Fission"
    , body = View.view model
    }
