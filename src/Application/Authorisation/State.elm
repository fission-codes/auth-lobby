module Authorisation.State exposing (..)

import External.Context as External
import Json.Encode as Json
import List.Ext as List
import Maybe.Extra as Maybe
import Ports
import Radix exposing (..)
import RemoteData
import Return exposing (return)
import Ucan



-- 📣


allow : Manager
allow model =
    case model.externalContext of
        RemoteData.Success context ->
            let
                host =
                    Maybe.withDefault "" model.usedUsername ++ "." ++ model.dataRootDomain

                resources =
                    []
                        -----------------------------------------
                        -- App Folder (Private)
                        -----------------------------------------
                        |> Maybe.unwrap
                            identity
                            (Ucan.AppFolder >> Ucan.fsResource host >> (::))
                            context.app
                        -----------------------------------------
                        -- Private paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (Ucan.PrivatePath >> Ucan.fsResource host)
                                context.privatePaths
                            )
                        -----------------------------------------
                        -- Public paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (Ucan.PublicPath >> Ucan.fsResource host)
                                context.publicPaths
                            )

                capabilities =
                    List.map
                        (\resource ->
                            { lifetimeInSeconds = context.lifetimeInSeconds
                            , resource = resource
                            , potency = Ucan.potency.all
                            }
                        )
                        resources
            in
            ( model
            , Ports.linkApp
                { did = context.didWrite
                , capabilities = capabilities
                }
            )

        _ ->
            Return.singleton model


deny : Manager
deny model =
    model.externalContext
        |> External.redirectCommand (Err "DENIED")
        |> return model


gotUcansForApplication : { readKey : String, ucans : List String } -> Manager
gotUcansForApplication { readKey, ucans } model =
    let
        username =
            Maybe.withDefault "" model.usedUsername

        redirection =
            { newUser = model.reCreateAccount == RemoteData.Success ()
            , readKey = readKey
            , ucans = ucans
            , username = username
            }
    in
    model.externalContext
        |> External.redirectCommand (Ok redirection)
        |> return model
