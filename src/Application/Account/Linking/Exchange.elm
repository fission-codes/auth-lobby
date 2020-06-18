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
    = Inquirer InquiryStep
    | Authoriser



-- 🛠


proceed : Maybe String -> Json.Decode.Value -> Exchange -> ( Exchange, Cmd msg )
proceed maybeUsername json exchange =
    -- TODO
    return exchange Cmd.none



-- INQUIRER


type InquiryStep
    = EstablishConnection
    | ConstructUcan


type alias Inquiry =
    -- We're using () as a placeholder here,
    -- will be filled in by the javascript side later.
    { did : ()
    , nonceRandom : String
    , nonceUser : String

    --
    , signature : ()
    }


inquire : String -> ( String, String ) -> ( Exchange, Cmd msg )
inquire username ( nonceRandom, nonceUser ) =
    { did = ()
    , nonceRandom = nonceRandom
    , nonceUser = nonceUser

    --
    , signature = ()
    }
        |> encodeInquiry
        |> Tuple.pair (Just username)
        |> Ports.publishOnSecureChannel
        |> return
            { didOtherSide = Nothing
            , nonceRandom = Just nonceRandom
            , nonceUser = Just nonceUser
            , side = Inquirer EstablishConnection
            }


encodeInquiry : Inquiry -> Json.Encode.Value
encodeInquiry inquiry =
    Json.Encode.object
        [ ( "did", Json.Encode.null )
        , ( "nonceRandom", Json.Encode.string inquiry.nonceRandom )
        , ( "nonceUser", Json.Encode.string inquiry.nonceUser )
        , ( "signature", Json.Encode.null )
        ]



-- AUTHORIZER


type alias EstablishingResponse =
    { did : String
    , nonceRandom : String
    }


type alias UcanResponse =
    { ucan : String
    }



-- ⚗️


nonceGenerator : Random.Generator String
nonceGenerator =
    Random.int 0 9
        |> Random.list 6
        |> Random.map (List.map String.fromInt >> String.concat)
