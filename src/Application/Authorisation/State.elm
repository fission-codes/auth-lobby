module Authorisation.State exposing (..)

import Authorisation.Suggest.Params as Suggest
import Common exposing (ifThenElse)
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
import Semver
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
                , canPermissionFiles =
                    context.sdkVersion
                        |> Maybe.map (\v -> Semver.greaterThan v (Semver.version 0 23 99 [] []))
                        |> Maybe.withDefault False
                , didWrite = context.didWrite
                , didExchange = context.didExchange
                , lifetimeInSeconds = context.lifetimeInSeconds
                , sharedRepo = context.sharedRepo

                -- TODO: Remove backwards compatibility
                , oldFlow = context.oldFlow
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


gotUcansForApplication : Suggest.Params -> Manager
gotUcansForApplication { cid, readKey, ucan } model =
    let
        username =
            Maybe.withDefault "" model.usedUsername

        newUser =
            model.reCreateAccount == RemoteData.Success ()

        redirection =
            case ( cid, Maybe.map2 Tuple.pair readKey ucan ) of
                ( Just c, _ ) ->
                    [ ( "authorised", c )
                    ]

                -- TODO: Remove backwards compatibility
                ( _, Just ( rk, uc ) ) ->
                    [ ( "readKey", rk )
                    , ( "ucans", uc )
                    ]

                _ ->
                    []
    in
    model.externalContext
        |> External.redirectCommand
            (redirection
                |> List.append
                    [ ( "newUser", ifThenElse newUser "t" "f" )
                    , ( "username", username )
                    ]
                |> Ok
            )
        |> return model
