module Account.Linking.Exchange exposing (..)

{-| The exchange happening over a secure channel.

Two sides, the inquirer and the authoriser.
The inquirer "inquires" and the authoriser "answers".

Certain steps of this are encrypted.

  - The `ConstructUcan` inquiry is encrypted with the authoriser's DID.
  - All answers are encrypted with the inquirer's DID.

-}

import Json.Decode
import Json.Encode
import Maybe.Extra as Maybe
import Ports
import Random
import Return exposing (return)



-- 🧩


type alias Exchange =
    { didOtherSide : Maybe String
    , nonceRandom : Maybe String
    , nonceUser : Maybe String
    , side : Side
    }


type Side
    = Inquirer Step
    | Authoriser Step


type Step
    = EstablishConnection
    | ConstructUcan



-- 🏔


placeholder =
    "PLACEHOLDER"


placeholderJson =
    Json.Encode.null



-- 🛠


{-| Take the next step in the exchange.

Flow:
Authoriser EstablishConnection → Inquirer EstablishConnection → Authoriser …

TODO:
Instead of silently ignoring JSON decoding errors,
show an error message or something.

-}
proceed : Maybe String -> Json.Decode.Value -> Exchange -> ( Exchange, Cmd msg )
proceed maybeUsername json exchange =
    case exchange.side of
        -----------------------------------------
        -- Inquirer
        -----------------------------------------
        Inquirer EstablishConnection ->
            json
                |> Json.Decode.decodeValue establishingResponseDecoder
                |> Result.mapError Json.Decode.errorToString
                |> Result.andThen
                    (\resp ->
                        if Just resp.nonceRandom == exchange.nonceRandom then
                            Ok resp

                        else
                            Err "Security violation, nonceRandom values don't match"
                    )
                |> Result.andThen
                    (\resp ->
                        case ( exchange.nonceRandom, exchange.nonceUser ) of
                            ( Just r, Just u ) ->
                                { did = placeholder
                                , nonceRandom = r
                                , nonceUser = u
                                , signature = placeholder
                                }
                                    |> Tuple.pair resp
                                    |> Ok

                            _ ->
                                Err "One of the nonces is missing"
                    )
                |> Result.map
                    (\( resp, inquiry ) ->
                        inquiry
                            |> encodeUcanInquiry
                            |> Tuple.pair maybeUsername
                            |> Ports.publishOnSecureChannel
                            |> return
                                { exchange
                                    | didOtherSide = Just resp.did
                                    , side = Inquirer ConstructUcan
                                }
                    )
                |> Result.withDefault
                    (Return.singleton exchange)

        Inquirer ConstructUcan ->
            let
                username =
                    Maybe.withDefault "" maybeUsername
            in
            json
                |> Json.Decode.decodeValue ucanResponseDecoder
                |> Result.mapError Json.Decode.errorToString
                |> Result.map (\{ ucan } -> Ports.linkedDevice { ucan = ucan, username = username })
                |> Result.withDefault Cmd.none
                |> return exchange

        -----------------------------------------
        -- Authoriser
        -----------------------------------------
        Authoriser EstablishConnection ->
            if Maybe.isNothing exchange.nonceRandom then
                json
                    |> Json.Decode.decodeValue
                        establishingInquiryDecoder
                    |> Result.map
                        (\inquiry ->
                            { did = placeholder
                            , nonceRandom = inquiry.nonceRandom
                            }
                                |> encodeEstablishingResponse
                                |> (\r -> ( maybeUsername, inquiry.did, r ))
                                |> Ports.publishEncryptedOnSecureChannel
                                |> return
                                    { didOtherSide = Just inquiry.did
                                    , nonceRandom = Just inquiry.nonceRandom
                                    , nonceUser = Nothing
                                    , side = Authoriser ConstructUcan
                                    }
                        )
                    |> Result.withDefault
                        (Return.singleton exchange)

            else
                Return.singleton exchange

        Authoriser ConstructUcan ->
            json
                |> Json.Decode.decodeValue ucanInquiryDecoder
                |> Result.mapError Json.Decode.errorToString
                |> Result.andThen
                    (\inquiry ->
                        if Just inquiry.nonceRandom == exchange.nonceRandom then
                            Ok inquiry

                        else
                            Err "nonceRandom doesn't match"
                    )
                |> Result.map
                    (\inquiry ->
                        { exchange | nonceUser = Just inquiry.nonceUser }
                    )
                |> Result.withDefault exchange
                |> Return.singleton



-- INQUIRER


inquire : String -> ( String, String ) -> ( Exchange, Cmd msg )
inquire username ( nonceRandom, nonceUser ) =
    { did = placeholder
    , nonceRandom = nonceRandom
    , signature = placeholder
    }
        |> encodeEstablishingInquiry
        |> Tuple.pair (Just username)
        |> Ports.publishOnSecureChannel
        |> return
            { didOtherSide = Nothing
            , nonceRandom = Just nonceRandom
            , nonceUser = Just nonceUser
            , side = Inquirer EstablishConnection
            }



-- INQUIRER  ▒▒  ESTABLISHING


type alias EstablishingInquiry =
    { did : String
    , nonceRandom : String
    , signature : String
    }


encodeEstablishingInquiry : EstablishingInquiry -> Json.Encode.Value
encodeEstablishingInquiry inquiry =
    Json.Encode.object
        [ ( "did", placeholderJson )
        , ( "nonceRandom", Json.Encode.string inquiry.nonceRandom )
        , ( "signature", placeholderJson )
        ]


establishingInquiryDecoder : Json.Decode.Decoder EstablishingInquiry
establishingInquiryDecoder =
    Json.Decode.map3
        EstablishingInquiry
        (Json.Decode.field "did" Json.Decode.string)
        (Json.Decode.field "nonceRandom" Json.Decode.string)
        (Json.Decode.field "signature" Json.Decode.string)



-- INQUIRER  ▒▒  UCAN


type alias UcanInquiry =
    { did : String
    , nonceRandom : String
    , nonceUser : String
    , signature : String
    }


encodeUcanInquiry : UcanInquiry -> Json.Encode.Value
encodeUcanInquiry inquiry =
    Json.Encode.object
        [ ( "did", placeholderJson )
        , ( "nonceRandom", Json.Encode.string inquiry.nonceRandom )
        , ( "nonceUser", Json.Encode.string inquiry.nonceUser )
        , ( "signature", placeholderJson )
        ]


ucanInquiryDecoder : Json.Decode.Decoder UcanInquiry
ucanInquiryDecoder =
    Json.Decode.map4
        UcanInquiry
        (Json.Decode.field "did" Json.Decode.string)
        (Json.Decode.field "nonceRandom" Json.Decode.string)
        (Json.Decode.field "nonceUser" Json.Decode.string)
        (Json.Decode.field "signature" Json.Decode.string)



-- AUTHORISER


initialAuthoriserExchange : Exchange
initialAuthoriserExchange =
    { didOtherSide = Nothing
    , nonceRandom = Nothing
    , nonceUser = Nothing
    , side = Authoriser EstablishConnection
    }



-- AUTHORISER  ▒▒  ESTABLISHING


type alias EstablishingResponse =
    { did : String
    , nonceRandom : String
    }


encodeEstablishingResponse : EstablishingResponse -> Json.Encode.Value
encodeEstablishingResponse resp =
    Json.Encode.object
        [ ( "did", placeholderJson )
        , ( "nonceRandom", Json.Encode.string resp.nonceRandom )
        ]


establishingResponseDecoder : Json.Decode.Decoder EstablishingResponse
establishingResponseDecoder =
    Json.Decode.map2
        EstablishingResponse
        (Json.Decode.field "did" Json.Decode.string)
        (Json.Decode.field "nonceRandom" Json.Decode.string)



-- AUTHORISER  ▒▒  UCAN


type alias UcanResponse =
    { ucan : String
    }


encodeUcanResponse : UcanResponse -> Json.Encode.Value
encodeUcanResponse resp =
    Json.Encode.object
        [ ( "ucan", placeholderJson )
        ]


ucanResponseDecoder : Json.Decode.Decoder UcanResponse
ucanResponseDecoder =
    Json.Decode.map
        UcanResponse
        (Json.Decode.field "ucan" Json.Decode.string)


ucanResponse : UcanResponse
ucanResponse =
    { ucan = placeholder }



-- ⚗️


nonceGenerator : Random.Generator String
nonceGenerator =
    Random.int 0 9
        |> Random.list 6
        |> Random.map (List.map String.fromInt >> String.concat)
