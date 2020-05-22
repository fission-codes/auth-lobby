port module Ports exposing (..)

-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port createAccount : { did : Maybe String, email : String, username : String } -> Cmd msg


port linkApp : { did : Maybe String } -> Cmd msg



-- 📰


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : ({ ucan : Maybe String } -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg
