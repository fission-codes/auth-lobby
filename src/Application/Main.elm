module Main exposing (main)

import Account.Creation.State as Creation
import Browser
import Browser.Navigation as Nav
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Debouncing
import Page exposing (Page(..))
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
            Page.fromUrl url

        pageCmd =
            if flags.usedKeyPair && page == Page.Link then
                Cmd.none

            else if flags.usedKeyPair then
                Nav.replaceUrl navKey (Page.toPath Page.Link)

            else
                Cmd.none
    in
    return
        { navKey = navKey
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
        pageCmd



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
        Choose ->
            "Fission"

        Create _ ->
            "Create account" ++ titleSuffix

        Link ->
            "Sign in" ++ titleSuffix


titleSuffix =
    "\u{2002}/\u{2002}Fission"
