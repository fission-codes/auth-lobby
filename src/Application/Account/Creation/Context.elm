module Account.Creation.Context exposing (..)

import Account.Linking.Exchange exposing (Exchange)
import RemoteData exposing (RemoteData)



-- 🧩


type alias Context =
    { email : String
    , exchange : Maybe Exchange
    , ionDid : String
    , ionDidIsValid : RemoteData () Bool
    , ionPrivateKey : String
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
    , ionDid = ""
    , ionDidIsValid = RemoteData.NotAsked
    , ionPrivateKey = ""
    , username = ""
    , usernameIsAvailable = RemoteData.NotAsked
    , usernameIsValid = True
    , waitingForDevices = False
    }
