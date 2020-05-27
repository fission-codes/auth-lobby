port module Ports exposing (..)

-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port createAccount : { did : String, email : String, username : String } -> Cmd msg


port linkApp : { did : String } -> Cmd msg



-- 📰


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : (() -> msg) -> Sub msg


port gotUcanForApplication : ({ ucan : String } -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg
