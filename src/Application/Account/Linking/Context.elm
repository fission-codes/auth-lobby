module Account.Linking.Context exposing (..)

import Account.Linking.Exchange exposing (Exchange)



-- 🧩


type alias Context =
    { exchange : Maybe Exchange
    , username : String
    , waitingForDevices : Bool
    }



-- 🌱


default : Context
default =
    { exchange = Nothing
    , username = ""
    , waitingForDevices = False
    }
