port module Ports exposing (..)

-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port createAccount : { didKey : Maybe String, email : String, username : String } -> Cmd msg



-- 📰


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : ({ ucan : String, username : String } -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg
