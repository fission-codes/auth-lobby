module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Page
import Radix exposing (Model, Msg(..))
import RemoteData
import Return exposing (return)
import Routing
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
        page =
            Page.fromUrl url

        pageCmd =
            if flags.hasLocalKeyPair && page == Page.Link then
                Cmd.none

            else if flags.hasLocalKeyPair then
                Nav.replaceUrl navKey (Page.toPath Page.Link)

            else
                Cmd.none
    in
    return
        { navKey = navKey
        , page = page
        , url = url

        -----------------------------------------
        -- Remote Data
        -----------------------------------------
        , reCreateAccount = RemoteData.NotAsked
        }
        pageCmd



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
