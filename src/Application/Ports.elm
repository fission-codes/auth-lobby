port module Ports exposing (..)

import Json.Decode as Json



-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port createAccount : { did : String, email : String, username : String } -> Cmd msg


port linkApp : { did : String } -> Cmd msg



-- 📣  ▒▒  SECURE CHANNEL


port openSecureChannel : Maybe String -> Cmd msg


port publishOnSecureChannel : ( Maybe String, Json.Value ) -> Cmd msg



-- 📰


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : (() -> msg) -> Sub msg


port gotUcanForApplication : ({ ucan : String } -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg



-- 📰  ▒▒  SECURE CHANNEL


port gotSecureChannelMessage : (Json.Value -> msg) -> Sub msg


port secureChannelOpened : (() -> msg) -> Sub msg


port secureChannelTimeout : (() -> msg) -> Sub msg
