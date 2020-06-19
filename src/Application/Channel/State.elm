module Channel.State exposing (..)

import Account.Linking.Exchange as Linking
import Json.Decode as Json
import Page
import Radix exposing (..)
import Random
import Return exposing (return)



-- 📣


gotMessage : Json.Value -> Manager
gotMessage json model =
    case model.page of
        Page.LinkAccount context ->
            case ( context.waitingForDevices, context.exchange ) of
                ( False, Just exchange ) ->
                    exchange
                        |> Linking.proceed (Just context.username) json
                        |> Return.map (\e -> { context | exchange = Just e })
                        |> Return.map (\c -> { model | page = Page.LinkAccount c })

                _ ->
                    Return.singleton model

        _ ->
            Return.singleton model


opened : Manager
opened model =
    case model.page of
        Page.LinkAccount context ->
            let
                newContext =
                    { context | waitingForDevices = False }
            in
            Linking.nonceGenerator
                |> Random.pair Linking.nonceGenerator
                |> Random.generate (StartLinkingExchange newContext)
                |> return model

        _ ->
            Return.singleton model


timeout : Manager
timeout =
    -- TODO
    Return.singleton
