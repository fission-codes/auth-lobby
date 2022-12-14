module Account.Creation.Context exposing (..)

import RemoteData exposing (RemoteData)



-- 🧩


type alias Context =
    { email : String
    , username : String
    , usernameIsAvailable : RemoteData () Bool
    , usernameIsValid : Bool
    , waitingForDevices : Bool
    }



-- 🌱


default : Context
default =
    { email = ""
    , username = ""
    , usernameIsAvailable = RemoteData.NotAsked
    , usernameIsValid = True
    , waitingForDevices = False
    }
