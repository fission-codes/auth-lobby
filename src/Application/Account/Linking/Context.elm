module Account.Linking.Context exposing (..)

import Account.Linking.Exchange exposing (Exchange)



-- 🧩


type alias Context =
    { exchange : Maybe Exchange
    , note : Maybe String
    , username : String
    , waitingForDevices : Bool
    }



-- 🌱


default : Context
default =
    { exchange = Nothing
    , note = Nothing
    , username = ""
    , waitingForDevices = False
    }
