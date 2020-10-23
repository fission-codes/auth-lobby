module Account.Linking.Exchange exposing (..)

{-| The exchange happening over a channel.

Two sides, the inquirer and the authoriser.
The inquirer "inquires" and the authoriser "authorises".

Specification:
<https://whitepaper.fission.codes/identity/device-linking>

Flow:
Outside the exchange, to start the flow,
the inquirer broadcasts their throwaway public exchange key.

1.  Authoriser starts a session key negotiation.
2.  Inquirer starts using session key if everything checks out.
3.  Inquirer sends a user challenge.
4.  Authoriser presents this challenge to the user.
5.  Authoriser user confirms the challenge.
6.  Authoriser sends UCAN and read key to the inquirer.

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)



-- 🧩


type alias Exchange =
    { didInquirer : Maybe String
    , didThrowaway : Maybe String
    , error : Maybe String
    , side : Side
    }


type Side
    = Authoriser Step
    | Inquirer Step


type Step
    = Broadcast
    | Negotiation
    | Delegation (List Int)



-- 🏔


alreadyAuthorised =
    "ALREADY_AUTHORISED"


alreadyInquired =
    "ALREADY_INQUIRED"


cancelMessage =
    Encode.object [ ( "linkStatus", Encode.string "DENIED" ) ]


placeholder =
    "PLACEHOLDER"


placeholderJson =
    Encode.null


stepSubject : Side -> Maybe String
stepSubject side =
    case side of
        Authoriser Broadcast ->
            Nothing

        Inquirer Broadcast ->
            Just "TEMPORARY_EXCHANGE_KEY"

        Authoriser Negotiation ->
            Just "SESSION_KEY"

        Inquirer Negotiation ->
            Just "USER_CHALLENGE"

        Authoriser (Delegation _) ->
            Just "READ_KEY_&_UCAN"

        Inquirer (Delegation _) ->
            Nothing



-- 🛠


{-| Take the next step in the exchange.

Flow:
Authoriser EstablishConnection → Inquirer EstablishConnection → Authoriser …

-}
proceed : Maybe String -> Decode.Value -> Exchange -> ( Exchange, Cmd msg )
proceed maybeUsername json exchange =
    case exchange.side of
        -----------------------------------------
        -- Authoriser
        -----------------------------------------
        Authoriser Broadcast ->
            ( exchange, Cmd.none )

        Authoriser Negotiation ->
            json
                |> Decode.decodeValue (Decode.field "msg" Decode.string)
                |> Result.mapError Decode.errorToString
                |> Result.map
                    (\didThrowaway ->
                        ( maybeUsername
                        , stepSubject exchange.side
                        , Encode.object [ ( "didThrowaway", Encode.string didThrowaway ) ]
                        )
                            |> Ports.publishOnChannel
                            |> return
                                { exchange
                                    | didThrowaway = Just didThrowaway
                                    , side = Authoriser (Delegation [])
                                }
                    )
                |> handleJsonResult exchange

        Authoriser (Delegation _) ->
            json
                |> Decode.decodeValue didAndPinDecoder
                |> Result.mapError Decode.errorToString
                |> Result.map
                    (\{ did, pin } ->
                        Return.singleton
                            { exchange
                                | didInquirer = Just did
                                , side = Authoriser (Delegation pin)
                            }
                    )
                |> handleJsonResult exchange

        -----------------------------------------
        -- Inquirer
        -----------------------------------------
        Inquirer Broadcast ->
            [ Ports.openChannel maybeUsername
            , Ports.publishOnChannel
                ( maybeUsername
                , stepSubject exchange.side
                , Encode.null
                )
            ]
                |> Cmd.batch
                |> return { exchange | side = Inquirer Negotiation }

        Inquirer Negotiation ->
            json
                |> Decode.decodeValue (Decode.field "msg" <| Decode.list Decode.int)
                |> Result.mapError Decode.errorToString
                |> Result.map
                    (\pin ->
                        ( maybeUsername
                        , stepSubject exchange.side
                        , Encode.object [ ( "pin", Encode.list Encode.int pin ) ]
                        )
                            |> Ports.publishOnChannel
                            |> return { exchange | side = Inquirer (Delegation pin) }
                    )
                |> handleJsonResult exchange

        Inquirer (Delegation _) ->
            json
                |> Decode.decodeValue readKeyAndUcanDecoder
                |> Result.mapError Decode.errorToString
                |> Result.map
                    (\{ readKey, ucan } ->
                        Ports.linkedDevice
                            { readKey = readKey
                            , ucan = ucan
                            , username = Maybe.withDefault "" maybeUsername
                            }
                    )
                |> Result.map (Tuple.pair exchange)
                |> handleJsonResult exchange



-- INQUIRER


initialInquirerExchange : Exchange
initialInquirerExchange =
    { didInquirer = Nothing
    , didThrowaway = Nothing
    , error = Nothing
    , side = Inquirer Broadcast
    }



-- AUTHORISER


initialAuthoriserExchange : Exchange
initialAuthoriserExchange =
    { didInquirer = Nothing
    , didThrowaway = Nothing
    , error = Nothing
    , side = Authoriser Negotiation
    }



-- DID & PIN


didAndPinDecoder : Decoder { did : String, pin : List Int }
didAndPinDecoder =
    Decode.map2
        (\d p -> { did = d, pin = p })
        (Decode.field "did" Decode.string)
        (Decode.field "pin" <| Decode.list Decode.int)



-- READ KEY & UCAN


readKeyAndUcanDecoder : Decoder { readKey : String, ucan : String }
readKeyAndUcanDecoder =
    Decode.map2
        (\r u -> { readKey = r, ucan = u })
        (Decode.field "readKey" Decode.string)
        (Decode.field "ucan" Decode.string)



-- ⚗️


handleJsonResult : Exchange -> Result String ( Exchange, Cmd msg ) -> ( Exchange, Cmd msg )
handleJsonResult exchange result =
    case result of
        Ok r ->
            r

        Err e ->
            Return.singleton { exchange | error = Just e }
