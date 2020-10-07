module Account.Creation.Context exposing (..)

import Account.Linking.Exchange exposing (Exchange)
import RemoteData exposing (RemoteData)



-- 🧩


type alias Context =
    { email : String
    , exchange : Maybe Exchange
    , username : String
    , usernameIsAvailable : RemoteData () Bool
    , usernameIsValid : Bool
    , waitingForDevices : Bool
    }



-- 🌱


default : Context
default =
    { email = ""
    , exchange = Nothing
    , username = ""
    , usernameIsAvailable = RemoteData.NotAsked
    , usernameIsValid = True
    , waitingForDevices = False
    }
