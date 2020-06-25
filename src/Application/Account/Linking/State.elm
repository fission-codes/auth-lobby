module Account.Linking.State exposing (..)

import Account.Linking.Context as Context exposing (Context)
import Account.Linking.Exchange as Exchange exposing (Exchange)
import Page
import Ports
import Radix exposing (..)
import Return exposing (return)



-- 📣


cancel : Manager
cancel model =
    -- TODO: Publish message on channel that link has been cancelled
    Return.singleton { model | page = Page.SuggestAuthorisation }


gotLinked : { username : String } -> Manager
gotLinked { username } model =
    Return.singleton
        { model
            | page = Page.SuggestAuthorisation
            , usedUsername = Just username
        }


gotUsernameInput : String -> Manager
gotUsernameInput input =
    adjustContext
        (\c -> { c | username = input })


linkAccount : Context -> Manager
linkAccount context model =
    return
        { model | page = Page.LinkAccount { context | waitingForDevices = True } }
        (Ports.openSecureChannel <| Just context.username)


sendUcan : Exchange -> Manager
sendUcan exchange model =
    case exchange.didOtherSide of
        Just didOtherSide ->
            Exchange.ucanResponse
                |> Exchange.encodeUcanResponse
                |> (\r -> ( model.usedUsername, didOtherSide, r ))
                |> Ports.publishEncryptedOnSecureChannel
                |> return { model | page = Page.SuggestAuthorisation }

        Nothing ->
            Return.singleton model


startExchange : Context -> ( String, String ) -> Manager
startExchange context nonces model =
    nonces
        |> Exchange.inquire context.username
        |> Return.map
            (\e ->
                { context | exchange = Just e }
            )
        |> Return.map
            (\c ->
                { model | page = Page.LinkAccount c }
            )



-- 🛠


adjustContext : (Context -> Context) -> Manager
adjustContext mapFn model =
    case model.page of
        Page.LinkAccount context ->
            Return.singleton { model | page = Page.LinkAccount (mapFn context) }

        _ ->
            Return.singleton model
