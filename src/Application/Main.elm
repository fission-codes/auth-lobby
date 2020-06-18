module Main exposing (main)

import Account.Creation.Context
import Account.Creation.State as Creation
import Account.Linking.Context
import Account.Linking.State as Linking
import Authorisation.State as Authorisation
import Browser
import Browser.Navigation as Nav
import Channel.State as Channel
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Debouncing
import External.Context
import Maybe.Extra as Maybe
import Page
import Ports
import Radix exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Return exposing (return)
import Routing
import Url exposing (Url)
import View



-- ⛩


type alias Flags =
    { dataRootDomain : String
    , usedUsername : Maybe String
    }


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
        externalContext =
            External.Context.extractFromUrl url

        page =
            if Maybe.isJust flags.usedUsername then
                Page.SuggestAuthorisation

            else
                case RemoteData.map .newUser externalContext of
                    Success (Just True) ->
                        Page.CreateAccount Account.Creation.Context.default

                    Success (Just False) ->
                        Page.LinkAccount Account.Linking.Context.default

                    _ ->
                        Page.Choose
    in
    return
        { dataRootDomain = flags.dataRootDomain
        , externalContext = externalContext
        , navKey = navKey
        , page = page
        , url = url
        , usedUsername = flags.usedUsername

        -----------------------------------------
        -- Debouncers
        -----------------------------------------
        , usernameAvailabilityDebouncer = Debouncing.usernameAvailability.debouncer

        -----------------------------------------
        -- Remote Data
        -----------------------------------------
        , reCreateAccount = RemoteData.NotAsked
        }
        -- If authenticated, subscribe to the pubsub channel.
        (case flags.usedUsername of
            Just _ ->
                Ports.openSecureChannel Nothing

            Nothing ->
                Cmd.none
        )



-- 📣


update : Msg -> Radix.Manager
update msg =
    case msg of
        Bypassed ->
            Return.singleton

        -----------------------------------------
        -- Authorisation
        -----------------------------------------
        AllowAuthorisation ->
            Authorisation.allow

        DenyAuthorisation ->
            Authorisation.deny

        GotUcanForApplication a ->
            Authorisation.gotUcanForApplication a

        -----------------------------------------
        -- Create
        -----------------------------------------
        CheckIfUsernameIsAvailable ->
            Creation.checkIfUsernameIsAvailable

        CreateAccount a ->
            Creation.createAccount a

        GotCreateAccountFailure a ->
            Creation.gotCreateAccountFailure a

        GotCreateAccountSuccess ->
            Creation.gotCreateAccountSuccess

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
        -- Linking
        -----------------------------------------
        GotLinkUsernameInput a ->
            Linking.gotUsernameInput a

        LinkAccount a ->
            Linking.linkAccount a

        StartLinkingExchange a b ->
            Linking.startExchange a b

        -----------------------------------------
        -- Routing
        -----------------------------------------
        GoToPage a ->
            Routing.goToPage a

        UrlChanged a ->
            Routing.urlChanged a

        UrlRequested a ->
            Routing.urlRequested a

        -----------------------------------------
        -- Secure Channel
        -----------------------------------------
        GotSecureChannelMessage a ->
            Channel.gotMessage a

        SecureChannelOpened ->
            Channel.opened

        SecureChannelTimeout ->
            Channel.timeout



-- 📰


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.gotCreateAccountFailure GotCreateAccountFailure
        , Ports.gotCreateAccountSuccess (\_ -> GotCreateAccountSuccess)
        , Ports.gotUcanForApplication GotUcanForApplication
        , Ports.gotUsernameAvailability GotUsernameAvailability

        -- Secure Channel
        -----------------
        , Ports.gotSecureChannelMessage GotSecureChannelMessage
        , Ports.secureChannelOpened (\_ -> SecureChannelOpened)
        , Ports.secureChannelTimeout (\_ -> SecureChannelTimeout)
        ]



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = title model ++ titleSuffix model
    , body = View.view model
    }


title : Model -> String
title model =
    case model.page of
        Page.Choose ->
            "Fission"

        Page.CreateAccount _ ->
            "Create account"

        Page.LinkAccount _ ->
            "Sign in"

        Page.SuggestAuthorisation ->
            "Authorise"

        Page.PerformingAuthorisation ->
            "Granting access"


titleSuffix : Model -> String
titleSuffix model =
    case model.page of
        Page.Choose ->
            ""

        _ ->
            " - Fission"
