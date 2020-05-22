module External.Application exposing (..)

import Radix exposing (..)
import Return exposing (return)


gotUcanForApplication : { ucan : String } -> Manager
gotUcanForApplication { ucan } model =
    Return.singleton model
