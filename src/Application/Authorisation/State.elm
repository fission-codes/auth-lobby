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
                            ((\a -> "private/Apps/" ++ a ++ "/") >> Tuple.pair "wnfs" >> (::))
                            context.app
                        -----------------------------------------
                        -- App Folder (Public)
                        -----------------------------------------
                        |> Maybe.unwrap
                            identity
                            ((\a -> "public/Apps/" ++ a ++ "/") >> Tuple.pair "wnfs" >> (::))
                            context.app
                        -----------------------------------------
                        -- Private paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (String.append "private/" >> Tuple.pair "wnfs")
                                context.privatePaths
                            )
                        -----------------------------------------
                        -- Public paths
                        -----------------------------------------
                        |> List.prepend
                            (List.map
                                (String.append "public/" >> Tuple.pair "wnfs")
                                context.publicPaths
                            )
            in
            ( model
            , Ports.linkApp
                { did = context.did
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
