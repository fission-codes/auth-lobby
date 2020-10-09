module Channel.State exposing (..)

import Account.Linking.Context as LinkingContext
import Account.Linking.Exchange as LinkingExchange
import Json.Decode as Json
import Json.Encode
import Maybe.Extra as Maybe
import Page
import Ports
import Radix exposing (..)
import Random
import Return exposing (return)



-- 📣


gotInvalidRootDid : Manager
gotInvalidRootDid model =
    case model.page of
        -----------------------------------------
        -- Link Account Page
        -----------------------------------------
        Page.LinkAccount context ->
            { context | note = Just "Couldn't find that user", waitingForDevices = False }
                |> Page.LinkAccount
                |> (\page -> { model | page = page })
                |> Return.singleton

        -----------------------------------------
        -- *
        -----------------------------------------
        _ ->
            Return.singleton model


gotMessage : Json.Value -> Manager
gotMessage json model =
    case model.page of
        -----------------------------------------
        -- Create Account Page
        -----------------------------------------
        Page.CreateAccount context ->
            case context.exchange of
                Just exchange ->
                    let
                        maybeUsername =
                            case exchange.side of
                                LinkingExchange.Inquirer _ ->
                                    Just context.username

                                LinkingExchange.Authoriser _ ->
                                    model.usedUsername
                    in
                    exchange
                        |> LinkingExchange.proceed maybeUsername json
                        |> Return.map (\e -> { context | exchange = Just e })
                        |> Return.map (\c -> { model | page = Page.CreateAccount c })

                -- Scenario:
                -- User has just created an account and is linking a second device.
                _ ->
                    LinkingExchange.initialAuthoriserExchange
                        |> LinkingExchange.proceed model.usedUsername json
                        |> Return.map (\e -> { context | exchange = Just e, waitingForDevices = False })
                        |> Return.map (\c -> { model | page = Page.CreateAccount c })

        -----------------------------------------
        -- Link Account Page
        -----------------------------------------
        Page.LinkAccount context ->
            case context.exchange of
                Just exchange ->
                    let
                        maybeUsername =
                            case exchange.side of
                                LinkingExchange.Inquirer _ ->
                                    Just context.username

                                LinkingExchange.Authoriser _ ->
                                    model.usedUsername
                    in
                    exchange
                        |> LinkingExchange.proceed maybeUsername json
                        |> Return.map (\e -> { context | exchange = Just e })
                        |> Return.map (\c -> { model | page = Page.LinkAccount c })

                -- This scenario isn't accounted for, because normally
                -- the user on the already authenticated device will
                -- not be on the link-account page (yet). See `case`
                -- branch at the bottom of this function 👇 for that side.
                _ ->
                    Return.singleton model

        -----------------------------------------
        -- *
        -----------------------------------------
        -- Scenario:
        -- User is authenticated and is listening
        -- for incoming linking requests.
        _ ->
            let
                isAuthenticated =
                    Maybe.isJust model.usedUsername

                context =
                    LinkingContext.default
            in
            if isAuthenticated then
                LinkingExchange.initialAuthoriserExchange
                    |> LinkingExchange.proceed model.usedUsername json
                    |> Return.map (\e -> { context | exchange = Just e })
                    |> Return.map (\c -> { model | page = Page.LinkAccount c })

            else
                Return.singleton model


opened : String -> Manager
opened from model =
    case model.page of
        -----------------------------------------
        -- Link Account Page
        -----------------------------------------
        Page.LinkAccount context ->
            if context.waitingForDevices then
                LinkingExchange.nonceGenerator
                    |> Random.pair LinkingExchange.nonceGenerator
                    |> Random.generate StartExchange
                    |> return model

            else
                alreadyLinking model

        -----------------------------------------
        -- *
        -----------------------------------------
        _ ->
            Return.singleton model


startExchange : ( String, String ) -> Manager
startExchange nonces model =
    case model.page of
        -----------------------------------------
        -- Link Account Page
        -----------------------------------------
        Page.LinkAccount context ->
            nonces
                |> LinkingExchange.inquire context.username
                |> Return.map
                    (\e ->
                        { context | exchange = Just e, waitingForDevices = False }
                    )
                |> Return.map
                    (\c ->
                        { model | page = Page.LinkAccount c }
                    )

        -----------------------------------------
        -- *
        -----------------------------------------
        _ ->
            Return.singleton model



-- ㊙️


alreadyLinking : Manager
alreadyLinking model =
    -- TODO: Let the other device know the linking process
    --       has already started on another device.
    --
    -- ( maybeUsername
    -- , Json.Encode.string (LinkingExchange.alreadyAuthorised ++ "-" ++ from)
    -- )
    --     |> Ports.publishOnSecureChannel
    --     |> return model
    Return.singleton model
