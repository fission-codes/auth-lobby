module Authorisation.State exposing (..)

import External.Context as External exposing (Resource(..))
import Json.Encode as Json
import Ports
import Radix exposing (..)
import RemoteData
import Return exposing (return)



-- 📣


allow : Manager
allow model =
    case model.externalContext of
        RemoteData.Success context ->
            ( model
            , Ports.linkApp
                { did = context.did
                , lifetimeInSeconds = context.lifetimeInSeconds
                , resource = encodeResource context.resource
                }
            )

        _ ->
            Return.singleton model


deny : Manager
deny model =
    model.externalContext
        |> External.redirectCommand (Err "DENIED")
        |> return model


gotUcanForApplication : { ucan : String } -> Manager
gotUcanForApplication { ucan } model =
    let
        username =
            Maybe.withDefault "" model.usedUsername

        redirection =
            { newUser = model.reCreateAccount == RemoteData.Success ()
            , ucan = ucan
            , username = username
            }
    in
    model.externalContext
        |> External.redirectCommand (Ok redirection)
        |> return model



-- ㊙️


encodeResource : Resource -> String
encodeResource resource =
    case resource of
        Everything ->
            "*"

        Resources dict ->
            Json.encode 0 (Json.dict identity Json.string dict)
