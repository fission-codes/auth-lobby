port module Ports exposing (..)

import Authorisation.Suggest.Params as Suggest
import Json.Decode as Json



-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port copyToClipboard : String -> Cmd msg


port createAccount : { did : String, email : String, username : String } -> Cmd msg


port focusOnForm : () -> Cmd msg


port leave : () -> Cmd msg


port linkApp :
    { attenuation :
        List
            { capability : String
            , resource : ( String, String )
            }
    , didWrite : String
    , didExchange : String
    , lifetimeInSeconds : Int

    -- TODO: Remove backwards compatibility
    , oldFlow : Bool
    }
    -> Cmd msg


port linkedDevice :
    { readKey : String
    , ucan : String
    , username : String
    }
    -> Cmd msg



-- 📣  ▒▒  CHANNEL


port closeChannel : () -> Cmd msg


port openChannel : Maybe String -> Cmd msg


port publishOnChannel : ( Maybe String, Maybe String, Json.Value ) -> Cmd msg



-- 📰


port cancelLink : ({ onBothSides : Bool } -> msg) -> Sub msg


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : (() -> msg) -> Sub msg


port gotLinked : ({ username : String } -> msg) -> Sub msg


port gotLinkAppError : (String -> msg) -> Sub msg


port gotLinkExchangeError : (String -> msg) -> Sub msg


port gotUcansForApplication : (Suggest.Params -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg



-- 📰  ▒▒  SECURE CHANNEL


port gotInvalidRootDid : (() -> msg) -> Sub msg


port gotChannelMessage : (Json.Value -> msg) -> Sub msg
