module Authorisation.State exposing (..)

import External.Context as External
import Json.Encode as Json
import List.Ext as List
import Maybe.Extra as Maybe
import Ports
import Radix exposing (..)
import RemoteData
import Return exposing (return)



-- 📣


allow : Manager
allow model =
    case model.externalContext of
        RemoteData.Success context ->
            let
                resources =
                    []
                        -----------------------------------------
                        -- App Folder (Private)
                        -----------------------------------------
                        |> Maybe.unwrap
                            identity
                            ((\a -> "private/Apps/" ++ a ++ "/") >> addFilesystemPrefix >> (::))
                            context.app
                        -----------------------------------------
                        -- Private paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (String.append "private/" >> addFilesystemPrefix)
                                context.privatePaths
                            )
                        -----------------------------------------
                        -- Public paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (String.append "public/" >> addFilesystemPrefix)
                                context.publicPaths
                            )
            in
            ( model
            , Ports.linkApp
                { did = context.didWrite
                , lifetimeInSeconds = context.lifetimeInSeconds
                , resources = resources
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



-- ㊙️


addFilesystemPrefix =
    Tuple.pair "dnslink"
