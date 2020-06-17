module Channel.State exposing (..)

import Json.Decode as Json
import Page
import Radix exposing (..)
import Return exposing (return)



-- 📣


gotMessage : Json.Value -> Manager
gotMessage json model =
    Return.singleton model


opened : Manager
opened model =
    case model.page of
        Page.LinkAccount context ->
            -- TODO: Publish message to authenticate
            Return.singleton model

        _ ->
            Return.singleton model


timeout : Manager
timeout =
    Return.singleton
