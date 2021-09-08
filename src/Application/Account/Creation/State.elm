module Account.Creation.State exposing (..)

import Account.Common.State as Common
import Account.Creation.Context as Context exposing (Context)
import Account.Linking.Exchange as LinkingExchange
import Account.Linking.State as Linking
import Browser.Navigation as Nav
import Debouncing
import Http
import Maybe.Extra as Maybe
import Page
import Ports
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Return exposing (return)
import Return.Extra as Return
import Url



-- 📣


checkIfIonDidIsValid : Manager
checkIfIonDidIsValid model =
    case model.page of
        Page.CreateAccount context ->
            case context.ionDid of
                "" ->
                    Return.singleton model

                i ->
                    model
                        |> adjustContext
                            (\c -> { c | ionDidIsValid = Loading })
                        |> Return.command
                            (Ports.checkIfIonDidIsValid i)

        _ ->
            Return.singleton model


checkIfUsernameIsAvailable : Manager
checkIfUsernameIsAvailable model =
    case model.page of
        Page.CreateAccount context ->
            case context.username of
                "" ->
                    Return.singleton model

                u ->
                    model
                        |> adjustContext
                            (\c -> { c | usernameIsAvailable = Loading })
                        |> Return.command
                            (Ports.checkIfUsernameIsAvailable u)

        _ ->
            Return.singleton model


createAccount : Context -> Manager
createAccount context model =
    case ( context.usernameIsValid, context.usernameIsAvailable, context.ionDidIsValid ) of
        ( _, Success False, _ ) ->
            Return.singleton model

        ( _, _, Success False ) ->
            Return.singleton model

        ( True, _, Success True ) ->
            { ionDid = String.trim context.ionDid
            , ionPrivateKey = String.trim context.ionPrivateKey
            , email = String.trim context.email
            , username = String.trim context.username
            }
                |> Ports.createAccountWithIon
                |> return { model | reCreateAccount = Loading }

        ( True, _, NotAsked ) ->
            { did = Maybe.unwrap "" .didWrite (RemoteData.toMaybe model.externalContext)
            , email = String.trim context.email
            , username = String.trim context.username
            }
                |> Ports.createAccount
                |> return { model | reCreateAccount = Loading }

        _ ->
            Return.singleton model


gotCreateIonDidValid : { valid : Bool } -> Manager
gotCreateIonDidValid { valid } model =
    if valid then
        adjustContext
            (\c -> { c | ionDidIsValid = Success True })
            { model | reCreateAccount = NotAsked }

    else
        adjustContext
            (\c -> { c | ionDidIsValid = Failure () })
            { model | reCreateAccount = NotAsked }


gotCreateAccountFailure : String -> Manager
gotCreateAccountFailure err model =
    Return.singleton { model | reCreateAccount = Failure err }


gotCreateAccountSuccess : Manager
gotCreateAccountSuccess model =
    let
        maybeUsername =
            case model.page of
                Page.CreateAccount c ->
                    Just c.username

                _ ->
                    Nothing

        context =
            case model.page of
                Page.CreateAccount c ->
                    c

                _ ->
                    Context.default

        newContext =
            { context | waitingForDevices = True }
    in
    Linking.waitForRequests
        { model
            | page = Page.CreateAccount newContext
            , reCreateAccount = Success ()
        }


gotCreateEmailInput : String -> Manager
gotCreateEmailInput input model =
    adjustContext
        (\c -> { c | email = input })
        { model | reCreateAccount = NotAsked }


gotCreateIonDidInput : String -> Manager
gotCreateIonDidInput input model =
    { model | reCreateAccount = NotAsked }
        |> adjustContext
            (\c ->
                { c
                    | ionDid = input
                    , ionDidIsValid = Loading
                }
            )
        |> Return.command
            (CheckIfIonDidIsValid
                |> Debouncing.ionDidValid.provideInput
                |> Return.task
            )


gotCreateIonKeyInput : String -> Manager
gotCreateIonKeyInput input model =
    adjustContext
        (\c -> { c | ionPrivateKey = input })
        { model | reCreateAccount = NotAsked }


gotCreateUsernameInput : String -> Manager
gotCreateUsernameInput input model =
    { model | reCreateAccount = NotAsked }
        |> adjustContext
            (\c ->
                { c
                    | username = input
                    , usernameIsAvailable = Loading
                    , usernameIsValid = True
                }
            )
        |> Return.command
            (CheckIfUsernameIsAvailable
                |> Debouncing.usernameAvailability.provideInput
                |> Return.task
            )


gotUsernameAvailability : { available : Bool, valid : Bool } -> Manager
gotUsernameAvailability { available, valid } =
    adjustContext
        (\c ->
            if c.usernameIsAvailable /= Loading then
                c

            else if not valid then
                { c | usernameIsValid = False }

            else
                { c
                    | usernameIsAvailable = Success available
                    , usernameIsValid = True
                }
        )


skipLinkDuringSetup : Manager
skipLinkDuringSetup model =
    case model.page of
        Page.CreateAccount context ->
            model
                |> Common.afterAccountCreation context
                |> Return.command
                    (case model.externalContext of
                        NotAsked ->
                            Cmd.none

                        _ ->
                            Ports.closeChannel ()
                    )

        _ ->
            Return.singleton model



-- 🛠


adjustContext : (Context -> Context) -> Manager
adjustContext mapFn model =
    case model.page of
        Page.CreateAccount context ->
            Return.singleton { model | page = Page.CreateAccount (mapFn context) }

        _ ->
            Return.singleton model
