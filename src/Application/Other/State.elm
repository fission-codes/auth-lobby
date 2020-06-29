module Other.State exposing (..)

import Ports
import Radix exposing (Manager)
import Return exposing (return)



-- 📣


copyToClipboard : String -> Manager
copyToClipboard string model =
    string
        |> Ports.copyToClipboard
        |> return model
