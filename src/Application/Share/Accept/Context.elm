module Share.Accept.Context exposing (..)

import Share.Accept.Progress exposing (Progress)



-- 🌳


type alias Context =
    { progress : Progress
    , shareId : String
    , sharedBy : String
    }
