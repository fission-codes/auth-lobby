module Account.Creation.State exposing (..)

import Account.Creation.Context as Context exposing (Context)
import Browser.Navigation as Nav
import Debouncing
import External.Context as External
import Maybe.Extra as Maybe
import Page
import Ports
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Return exposing (return)
import Return.Extra as Return
import Url



-- 📣


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
    case ( context.usernameIsValid, context.usernameIsAvailable ) of
        ( _, Success False ) ->
            Return.singleton model

        ( True, _ ) ->
            let
                dnsLink =
                    context.username ++ ".fission.name"
            in
            { did = Maybe.map .did (RemoteData.toMaybe model.externalContext)
            , email = String.trim context.email
            , username = String.trim context.username
            }
                |> Ports.createAccount
                |> return { model | reCreateAccount = Loading }

        _ ->
            Return.singleton model


gotCreateAccountFailure : String -> Manager
gotCreateAccountFailure err model =
    Return.singleton { model | reCreateAccount = Failure err }


gotCreateAccountSuccess : { ucan : Maybe String } -> Manager
gotCreateAccountSuccess ({ ucan } as params) model =
    let
        maybeUsername =
            case model.page of
                Page.CreateAccount c ->
                    Just c.username

                _ ->
                    Nothing
    in
    Return.singleton
        { model
            | page = Page.SuggestAuthorisation
            , reCreateAccount = Success ()
            , usedUsername = maybeUsername
        }


gotCreateEmailInput : String -> Manager
gotCreateEmailInput input model =
    adjustContext
        (\c -> { c | email = input })
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



-- 🛠


adjustContext : (Context -> Context) -> Manager
adjustContext mapFn model =
    case model.page of
        Page.CreateAccount context ->
            Return.singleton { model | page = Page.CreateAccount (mapFn context) }

        _ ->
            Return.singleton model
