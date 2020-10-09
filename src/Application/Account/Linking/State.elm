module Account.Linking.State exposing (..)

import Account.Creation.State
import Account.Linking.Context as Context exposing (Context)
import Account.Linking.Exchange as Exchange exposing (Exchange)
import Json.Encode
import Page
import Ports
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Return exposing (return)



-- 📣


cancel : { onBothSides : Bool } -> Manager
cancel { onBothSides } model =
    case model.page of
        Page.CreateAccount context ->
            { context
                | exchange = Nothing
                , waitingForDevices = True
            }
                |> (\c -> Page.CreateAccount c)
                |> (\p -> { model | page = p })
                |> Return.singleton
                |> Return.command
                    (Ports.publishOnSecureChannel
                        ( Nothing
                        , Json.Encode.string Exchange.cancelMessage
                        )
                    )

        Page.LinkAccount context ->
            case Maybe.map .side context.exchange of
                Just (Exchange.Inquirer _) ->
                    Return.singleton { model | page = Page.Choose }

                Just (Exchange.Authoriser _) ->
                    return
                        { model | page = Page.SuggestAuthorisation }
                        (if onBothSides then
                            Ports.publishOnSecureChannel
                                ( Nothing
                                , Json.Encode.string Exchange.cancelMessage
                                )

                         else
                            Cmd.none
                        )

                Nothing ->
                    Return.singleton model

        _ ->
            Return.singleton model


gotExchangeError : String -> Manager
gotExchangeError error model =
    let
        context =
            case model.page of
                Page.LinkAccount c ->
                    c

                _ ->
                    Context.default
    in
    context.exchange
        |> Maybe.withDefault Exchange.initialAuthoriserExchange
        |> (\e -> { e | error = Just error })
        |> (\e -> { context | exchange = Just e })
        |> (\c -> { model | page = Page.LinkAccount c })
        |> Return.singleton


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
        (\c -> { c | note = Nothing, username = input })


linkAccount : Context -> Manager
linkAccount context model =
    case String.trim context.username of
        "" ->
            Return.singleton model

        username ->
            let
                newContext =
                    { context | username = username, waitingForDevices = True }
            in
            return
                { model | page = Page.LinkAccount newContext }
                (Ports.openSecureChannel <| Just username)


sendUcan : Exchange -> Manager
sendUcan exchange model =
    case exchange.didOtherSide of
        Just didOtherSide ->
            let
                makeCmd maybeUsername =
                    Exchange.ucanResponse
                        |> Exchange.encodeUcanResponse
                        |> (\r -> ( maybeUsername, didOtherSide, r ))
                        |> Ports.publishEncryptedOnSecureChannel
            in
            case model.page of
                Page.CreateAccount context ->
                    model
                        |> Account.Creation.State.afterAccountCreation context
                        |> Return.command (makeCmd <| Just context.username)
                        -- If redirecting elsewhere, close the pubsub channel.
                        |> Return.command
                            (case model.externalContext of
                                NotAsked ->
                                    Cmd.none

                                _ ->
                                    Ports.closeSecureChannel ()
                            )

                _ ->
                    return
                        { model | page = Page.Note "Device was successfully linked!\nYou can close this window now." }
                        (makeCmd model.usedUsername)

        Nothing ->
            Return.singleton model



-- 🛠


adjustContext : (Context -> Context) -> Manager
adjustContext mapFn model =
    case model.page of
        Page.LinkAccount context ->
            Return.singleton { model | page = Page.LinkAccount (mapFn context) }

        _ ->
            Return.singleton model
