module External.Application exposing (..)

import External.Context as External
import Radix exposing (..)
import Return exposing (return)


gotUcanForApplication : { ucan : String } -> Manager
gotUcanForApplication { ucan } model =
    let
        username =
            Maybe.withDefault "" model.usedUsername
    in
    model.externalContext
        |> External.redirectCommand { ucan = Just ucan, username = username }
        |> return model
