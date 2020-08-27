port module Ports exposing (..)

import Json.Decode as Json



-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port copyToClipboard : String -> Cmd msg


port createAccount : { did : String, email : String, username : String } -> Cmd msg


port linkApp :
    { did : String
    , attenuation :
        List
            { capability : String
            , lifetimeInSeconds : Int
            , resource : ( String, String )
            }
    }
    -> Cmd msg


port linkedDevice : { ucan : String, username : String } -> Cmd msg



-- 📣  ▒▒  SECURE CHANNEL


port closeSecureChannel : () -> Cmd msg


port openSecureChannel : Maybe String -> Cmd msg


port publishOnSecureChannel : ( Maybe String, Json.Value ) -> Cmd msg


port publishEncryptedOnSecureChannel : ( Maybe String, String, Json.Value ) -> Cmd msg



-- 📰


port cancelLink : (() -> msg) -> Sub msg


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : (() -> msg) -> Sub msg


port gotLinked : ({ username : String } -> msg) -> Sub msg


port gotLinkExchangeError : (String -> msg) -> Sub msg


port gotUcansForApplication : ({ readKey : String, ucans : List String } -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg



-- 📰  ▒▒  SECURE CHANNEL


port gotInvalidRootDid : (() -> msg) -> Sub msg


port gotSecureChannelMessage : (Json.Value -> msg) -> Sub msg


port secureChannelOpened : (() -> msg) -> Sub msg
