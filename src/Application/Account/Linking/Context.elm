module Account.Linking.Context exposing (..)

-- 🧩


type alias Context =
    { username : String
    }



-- 🌱


default : Context
default =
    { username = ""
    }
