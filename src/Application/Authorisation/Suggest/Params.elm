module Authorisation.Suggest.Params exposing (..)

-- 🌳


type alias Params =
    { cid : Maybe String

    -- TODO: Remove backwards compatibility
    , readKey : Maybe String
    , ucan : Maybe String
    }
