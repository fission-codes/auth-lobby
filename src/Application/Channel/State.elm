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
            context.exchange
                |> Maybe.map (Linking.proceed (Just context.username) json)
                |> Maybe.map (Return.map (\e -> { context | exchange = Just e }))
                |> Maybe.map (Return.map (\c -> { model | page = Page.LinkAccount c }))
                |> Maybe.withDefault (Return.singleton model)

        _ ->
            Return.singleton model


opened : Manager
opened model =
    case model.page of
        Page.LinkAccount context ->
            Linking.nonceGenerator
                |> Random.pair Linking.nonceGenerator
                |> Random.generate (StartLinkingExchange { context | requestOtherDevice = False })
                |> return model

        _ ->
            Return.singleton model


timeout : Manager
timeout =
    -- TODO
    Return.singleton
