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
                host =
                    Maybe.withDefault "" model.usedUsername ++ "." ++ model.dataRootDomain

                addFsPrefix =
                    addFilesystemPrefix host

                resources =
                    []
                        -----------------------------------------
                        -- App Folder (Private)
                        -----------------------------------------
                        |> Maybe.unwrap
                            identity
                            (String.append "private/Apps/" >> addFsPrefix >> (::))
                            context.app
                        -----------------------------------------
                        -- Private paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (String.append "private/" >> addFsPrefix)
                                context.privatePaths
                            )
                        -----------------------------------------
                        -- Public paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (String.append "public/" >> addFsPrefix)
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


addFilesystemPrefix host =
    String.append (host ++ "/") >> Tuple.pair "dnslink"
