module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Radix exposing (Model, Msg(..))
import Return
import Routing
import Screens
import Url exposing (Url)
import View



-- ⛩


type alias Flags =
    { hasLocalKeyPair : Bool }


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
    let
        screen =
            if flags.hasLocalKeyPair then
                -- TODO
                Screens.Link

            else
                Screens.Choose
    in
    Return.singleton
        { navKey = navKey
        , screen = screen
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
