port module Ports exposing (..)

import Json.Decode as Json



-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port copyToClipboard : String -> Cmd msg


port createAccount : { did : String, email : String, username : String } -> Cmd msg


port linkApp :
    { attenuation :
        List
            { capability : String
            , resource : ( String, String )
            }
    , didWrite : String
    , didExchange : String
    , lifetimeInSeconds : Int
    }
    -> Cmd msg


port linkedDevice :
    { readKey : String
    , ucan : String
    , username : String
    }
    -> Cmd msg



-- 📣  ▒▒  SECURE CHANNEL


port closeSecureChannel : () -> Cmd msg


port openSecureChannel : Maybe String -> Cmd msg


port publishOnSecureChannel : ( Maybe String, Json.Value ) -> Cmd msg


port publishEncryptedOnSecureChannel : ( Maybe String, String, Json.Value ) -> Cmd msg



-- 📰


port cancelLink : ({ onBothSides : Bool } -> msg) -> Sub msg


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : (() -> msg) -> Sub msg


port gotLinked : ({ username : String } -> msg) -> Sub msg


port gotLinkExchangeError : (String -> msg) -> Sub msg


port gotUcansForApplication : ({ readKey : String, ucans : List String } -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg



-- 📰  ▒▒  SECURE CHANNEL


port gotInvalidRootDid : (() -> msg) -> Sub msg


port gotSecureChannelMessage : (Json.Value -> msg) -> Sub msg


port secureChannelOpened : (String -> msg) -> Sub msg
