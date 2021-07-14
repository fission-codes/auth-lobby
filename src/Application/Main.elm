module Main exposing (main)

import Account.Creation.Context
import Account.Creation.State as Creation
import Account.Linking.Context
import Account.Linking.State as Linking
import Account.Linking.Url
import Authorisation.State as Authorisation
import Browser
import Browser.Navigation as Nav
import Channel.State as Channel
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Debouncing
import External.Context
import Maybe.Extra as Maybe
import Other.State as Other
import Page exposing (Page)
import Ports
import Radix exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Return exposing (return)
import Routing
import Theme.Defaults
import Theme.Url
import Url exposing (Url)
import Url.Parser as Url
import View



-- ⛩


type alias Flags =
    { apiDomain : String
    , dataRootDomain : String
    , usedUsername : Maybe String
    , version : String
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

        maybeThemePointer =
            Theme.Url.extractPointer url

        theme =
            case maybeThemePointer of
                Just _ ->
                    Loading

                Nothing ->
                    NotAsked

        page =
            determineInitialPage flags url externalContext
    in
    { apiDomain = flags.apiDomain
    , dataRootDomain = flags.dataRootDomain
    , externalContext = externalContext
    , navKey = navKey
    , page = page
    , theme = theme
    , url = url
    , usedUsername = flags.usedUsername
    , version = flags.version

    -----------------------------------------
    -- Debouncers
    -----------------------------------------
    , usernameAvailabilityDebouncer = Debouncing.usernameAvailability.debouncer

    -----------------------------------------
    -- Remote Data
    -----------------------------------------
    , reCreateAccount = RemoteData.NotAsked
    , reLinkApp = RemoteData.NotAsked
    }
        |> -- If authenticated, wait for incoming linking requests.
           (case flags.usedUsername of
                Just _ ->
                    Linking.waitForRequests

                Nothing ->
                    Return.singleton
           )
        |> Return.command
            (maybeThemePointer
                |> Maybe.map (Theme.Url.fetch flags.apiDomain)
                |> Maybe.withDefault Cmd.none
            )
        |> Return.command
            (case String.toLower url.path of
                "reset" ->
                    Nav.load "/reset/"

                _ ->
                    Cmd.none
            )


determineInitialPage : Flags -> Url -> External.Context.ParsedContext -> Page
determineInitialPage flags url externalContext =
    if Maybe.isJust flags.usedUsername then
        Page.SuggestAuthorisation

    else
        case RemoteData.map .newUser externalContext of
            Success (Just True) ->
                Page.CreateAccount Account.Creation.Context.default

            Success (Just False) ->
                Page.LinkAccount Account.Linking.Context.default

            _ ->
                let
                    context =
                        Account.Linking.Context.default

                    maybeUsername =
                        url
                            |> Url.parse (Url.query Account.Linking.Url.screenParamsParser)
                            |> Maybe.join
                in
                case maybeUsername of
                    Just username ->
                        Page.LinkAccount { context | username = username }

                    Nothing ->
                        Page.Choose



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

        GotLinkAppError a ->
            Authorisation.gotLinkAppError a

        GotUcansForApplication a ->
            Authorisation.gotUcansForApplication a

        -----------------------------------------
        -- Channel
        -----------------------------------------
        GotInvalidRootDid ->
            Channel.gotInvalidRootDid

        GotChannelMessage a ->
            Channel.gotMessage a

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

        SkipLinkDuringSetup ->
            Creation.skipLinkDuringSetup

        -----------------------------------------
        -- Debouncers
        -----------------------------------------
        UsernameAvailabilityDebouncerMsg a ->
            Debouncer.update update Debouncing.usernameAvailability.updateConfig a

        -----------------------------------------
        -- Linking
        -----------------------------------------
        CancelLink a ->
            Linking.cancel a

        GotLinked a ->
            Linking.gotLinked a

        GotLinkUsernameInput a ->
            Linking.gotUsernameInput a

        GotLinkExchangeError a ->
            Linking.gotExchangeError a

        LinkAccount a ->
            Linking.linkAccount a

        SendLinkingUcan a ->
            Linking.sendUcan a

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
        -- 🧿 Other things
        -----------------------------------------
        CopyToClipboard a ->
            Other.copyToClipboard a

        GotThemeViaHttp a ->
            Other.gotThemeViaHttp a

        GotThemeViaIpfs a ->
            Other.gotThemeViaIpfs a

        Leave ->
            Other.leave



-- 📰


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.cancelLink CancelLink
        , Ports.gotCreateAccountFailure GotCreateAccountFailure
        , Ports.gotCreateAccountSuccess (\_ -> GotCreateAccountSuccess)
        , Ports.gotLinked GotLinked
        , Ports.gotLinkAppError GotLinkAppError
        , Ports.gotLinkExchangeError GotLinkExchangeError
        , Ports.gotUcansForApplication GotUcansForApplication
        , Ports.gotUsernameAvailability GotUsernameAvailability

        -----------------------------------------
        -- Channel
        -----------------------------------------
        , Ports.gotInvalidRootDid (\_ -> GotInvalidRootDid)
        , Ports.gotChannelMessage GotChannelMessage
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

        Page.Note _ ->
            "Fission"

        Page.SuggestAuthorisation ->
            case model.externalContext of
                NotAsked ->
                    "Fission"

                _ ->
                    "Authorise"

        Page.PerformingAuthorisation ->
            "Granting access"


titleSuffix : Model -> String
titleSuffix model =
    case model.page of
        Page.Choose ->
            ""

        Page.SuggestAuthorisation ->
            case model.externalContext of
                NotAsked ->
                    ""

                _ ->
                    " - Fission"

        _ ->
            " - Fission"
