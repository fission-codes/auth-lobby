module Main exposing (main)

import Account.Creation.State as Creation
import Browser
import Browser.Navigation as Nav
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Debouncing
import External.Context
import Page
import Ports
import Radix exposing (Model, Msg(..))
import RemoteData
import Return exposing (return)
import Routing
import Url exposing (Url)
import View



-- ⛩


type alias Flags =
    { usedKeyPair : Bool }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = subscriptions
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
            if flags.usedKeyPair && url.path /= Page.toPath Page.LinkAccount then
                Page.LinkingApplication

            else
                Page.fromUrl url
    in
    return
        { externalContext = External.Context.extractFromUrl url
        , navKey = navKey
        , page = page
        , url = url

        -- Debouncers
        -------------
        , usernameAvailabilityDebouncer = Debouncing.usernameAvailability.debouncer

        -----------------------------------------
        -- Remote Data
        -----------------------------------------
        , reCreateAccount = RemoteData.NotAsked
        }
        Cmd.none



-- 📣


update : Msg -> Radix.Manager
update msg =
    case msg of
        Bypassed ->
            Return.singleton

        -----------------------------------------
        -- Create
        -----------------------------------------
        CheckIfUsernameIsAvailable ->
            Creation.checkIfUsernameIsAvailable

        CreateAccount a ->
            Creation.createAccount a

        GotCreateAccountFailure a ->
            Creation.gotCreateAccountFailure a

        GotCreateAccountSuccess a ->
            Creation.gotCreateAccountSuccess a

        GotCreateEmailInput a ->
            Creation.gotCreateEmailInput a

        GotCreateUsernameInput a ->
            Creation.gotCreateUsernameInput a

        GotUsernameAvailability a ->
            Creation.gotUsernameAvailability a

        -----------------------------------------
        -- Debouncers
        -----------------------------------------
        UsernameAvailabilityDebouncerMsg a ->
            Debouncer.update update Debouncing.usernameAvailability.updateConfig a

        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged a ->
            Routing.urlChanged a

        UrlRequested a ->
            Routing.urlRequested a



-- 📰


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.gotCreateAccountFailure GotCreateAccountFailure
        , Ports.gotCreateAccountSuccess GotCreateAccountSuccess
        , Ports.gotUsernameAvailability GotUsernameAvailability
        ]



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = title model
    , body = View.view model
    }


title : Model -> String
title model =
    case model.page of
        Page.Choose ->
            "Fission"

        Page.CreateAccount _ ->
            "Create account" ++ titleSuffix

        Page.LinkAccount ->
            "Sign in" ++ titleSuffix

        Page.LinkingApplication ->
            "Granting access"


titleSuffix =
    "\u{2002}/\u{2002}Fission"
