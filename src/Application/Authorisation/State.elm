module Authorisation.State exposing (..)

import Dict
import External.Context as External
import Json.Decode
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
                        -- App
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                Ucan.appResource
                                context.web
                            )
                        -----------------------------------------
                        -- App Folder (Private)
                        -----------------------------------------
                        |> Maybe.unwrap
                            identity
                            (Ucan.AppFolder >> Ucan.fsResource host >> (::))
                            context.appFolder
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

                attenuation =
                    List.map
                        (\resource ->
                            { resource = resource
                            , capability = Ucan.fsCapabilities.overwrite
                            }
                        )
                        resources
            in
            ( { model
                | reLinkApp = RemoteData.Loading
              }
            , Ports.linkApp
                { attenuation = attenuation
                , didWrite = context.didWrite
                , didExchange = context.didExchange
                , lifetimeInSeconds = context.lifetimeInSeconds
                }
            )

        _ ->
            Return.singleton model


deny : Manager
deny model =
    model.externalContext
        |> External.redirectCommand (Err "DENIED")
        |> return model


gotLinkAppError : String -> Manager
gotLinkAppError err model =
    Return.singleton { model | reLinkApp = RemoteData.Failure err }


gotUcansForApplication : { classified : String, ucans : List String } -> Manager
gotUcansForApplication { classified, ucans } model =
    let
        username =
            Maybe.withDefault "" model.usedUsername

        redirection =
            { classified = classified
            , newUser = model.reCreateAccount == RemoteData.Success ()
            , ucans = ucans
            , username = username
            }
    in
    model.externalContext
        |> External.redirectCommand (Ok redirection)
        |> return model
