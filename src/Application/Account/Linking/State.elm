module Account.Linking.State exposing (..)

import Account.Common.State as Common
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
                    (Ports.publishOnChannel
                        ( Nothing
                        , Nothing
                        , Exchange.cancelMessage
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
                            Ports.publishOnChannel
                                ( Nothing
                                , Nothing
                                , Exchange.cancelMessage
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
            Exchange.initialInquirerExchange
                |> Exchange.proceed (Just username) Json.Encode.null
                |> Return.map (\e -> { newContext | exchange = Just e })
                |> Return.map (\c -> { model | page = Page.LinkAccount c })


sendUcan : Exchange -> Manager
sendUcan exchange model =
    case exchange.didInquirer of
        Just didInquirer ->
            let
                makeCmd maybeUsername =
                    Ports.publishOnChannel
                        ( maybeUsername
                        , Exchange.stepSubject exchange.side
                        , Json.Encode.object [ ( "didInquirer", Json.Encode.string didInquirer ) ]
                        )
            in
            case model.page of
                Page.CreateAccount context ->
                    model
                        |> Common.afterAccountCreation context
                        |> Return.command (makeCmd <| Just context.username)

                _ ->
                    return
                        { model | page = Page.Note "Device was successfully linked!\nYou can close this window now." }
                        (makeCmd model.usedUsername)

        Nothing ->
            Return.singleton model


waitForRequests : Manager
waitForRequests model =
    return model (Ports.openChannel Nothing)



-- 🛠


adjustContext : (Context -> Context) -> Manager
adjustContext mapFn model =
    case model.page of
        Page.LinkAccount context ->
            Return.singleton { model | page = Page.LinkAccount (mapFn context) }

        _ ->
            Return.singleton model
