module Channel.State exposing (..)

import Account.Linking.Context as LinkingContext
import Account.Linking.Exchange as LinkingExchange
import Json.Decode as Json
import Page
import Radix exposing (..)
import Random
import Return exposing (return)



-- 📣


gotMessage : Json.Value -> Manager
gotMessage json model =
    case model.page of
        -----------------------------------------
        -- Link Account Page
        -----------------------------------------
        Page.LinkAccount context ->
            case context.exchange of
                Just exchange ->
                    let
                        username =
                            case exchange.side of
                                LinkingExchange.Inquirer _ ->
                                    Just context.username

                                LinkingExchange.Authoriser _ ->
                                    model.usedUsername
                    in
                    exchange
                        |> LinkingExchange.proceed username json
                        |> Return.map (\e -> { context | exchange = Just e })
                        |> Return.map (\c -> { model | page = Page.LinkAccount c })

                _ ->
                    Return.singleton model

        -----------------------------------------
        -- *
        -----------------------------------------
        _ ->
            let
                context =
                    LinkingContext.default
            in
            LinkingExchange.initialAuthoriserExchange
                |> LinkingExchange.proceed model.usedUsername json
                |> Return.map (\e -> { context | exchange = Just e })
                |> Return.map (\c -> { model | page = Page.LinkAccount c })


opened : Manager
opened model =
    case model.page of
        Page.LinkAccount context ->
            let
                newContext =
                    { context | waitingForDevices = False }
            in
            LinkingExchange.nonceGenerator
                |> Random.pair LinkingExchange.nonceGenerator
                |> Random.generate (StartLinkingExchange newContext)
                |> return model

        _ ->
            Return.singleton model
