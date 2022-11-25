module Account.Linking.State exposing (..)

import Account.Linking.Context exposing (Context)
import Account.Linking.Progress exposing (..)
import Page
import Ports
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Return exposing (return)



-- 📣


accountLinked : { username : String } -> Manager
accountLinked { username } model =
    Return.singleton
        { model
            | page = Page.SuggestAuthorisation
            , usedUsername = Just username
        }


cancelLinkAccount : Manager
cancelLinkAccount model =
    Return.singleton { model | page = Page.SuggestAuthorisation }


confirmProducerPin : Manager
confirmProducerPin model =
    return model (Ports.confirmLinkAccountPin ())


gotAccountPin : List Int -> Manager
gotAccountPin pin model =
    let
        page =
            case model.page of
                Page.LinkAccount context ->
                    Page.LinkAccount context

                _ ->
                    Page.LinkAccount Account.Linking.Context.initProducerLink
    in
    adjustContext
        (\c ->
            let
                progress =
                    case c.progress of
                        Just (Consumer WaitingOnProducer) ->
                            Just (Consumer <| ConsumerPin pin)

                        Just (Producer WaitingOnConsumer) ->
                            Just (Producer <| ProducerPin pin)

                        a ->
                            a
            in
            { c | progress = progress, waitingForDevices = False }
        )
        { model | page = page }


gotUsernameInput : String -> Manager
gotUsernameInput input =
    adjustContext
        (\c -> { c | note = Nothing, username = input })


linkAccount : Context -> Manager
linkAccount context model =
    case String.trim context.username of
        "" ->
            Return.singleton model

        username ->
            let
                newContext =
                    { context
                        | progress = Just (Consumer WaitingOnProducer)
                        , username = username
                        , waitingForDevices = True
                    }
            in
            return
                { model | page = Page.LinkAccount newContext }
                (Ports.createAccountConsumer username)


waitForRequests : Manager
waitForRequests model =
    return model (Ports.createAccountProducer ())



-- 🛠


adjustContext : (Context -> Context) -> Manager
adjustContext mapFn model =
    case model.page of
        Page.LinkAccount context ->
            Return.singleton { model | page = Page.LinkAccount (mapFn context) }

        _ ->
            Return.singleton model
