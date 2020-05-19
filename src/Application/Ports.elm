port module Ports exposing (..)

-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port createAccount : { email : String, username : String } -> Cmd msg



-- 📰


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : ({ username : String } -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg
