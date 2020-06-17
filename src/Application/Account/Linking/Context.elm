module Account.Linking.Context exposing (..)

-- 🧩


type alias Context =
    { requestOtherDevice : Bool
    , username : String
    }



-- 🌱


default : Context
default =
    { requestOtherDevice = False
    , username = ""
    }
