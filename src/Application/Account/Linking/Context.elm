module Account.Linking.Context exposing (..)

import Account.Linking.Exchange exposing (Exchange)



-- 🧩


type alias Context =
    { exchange : Maybe Exchange
    , requestOtherDevice : Bool
    , username : String
    }



-- 🌱


default : Context
default =
    { exchange = Nothing
    , requestOtherDevice = False
    , username = ""
    }
