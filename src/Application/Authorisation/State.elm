module Authorisation.State exposing (..)

import Authorisation.Suggest.Params as Suggest
import Authorisation.Suggest.Progress as Progress exposing (..)
import Common exposing (ifThenElse)
import Dict
import External.Context as External
import Flow exposing (..)
import Json.Decode
import Json.Encode as Json
import List.Ext as List
import Maybe.Extra as Maybe
import Ports
import Radix exposing (..)
import RemoteData
import Result.Extra as Result
import Return exposing (return)
import Semver
import Time
import Ucan



-- 📣


allow : Time.Posix -> Manager
allow currentTime model =
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
                | reLinkApp =
                    Flow.InProgress
                        { progress = Progress.Starting
                        , progressTime = Time.posixToMillis currentTime
                        , startTime = Time.posixToMillis currentTime
                        }
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
                , keyInSessionStorage = context.keyInSessionStorage
                , raw =
                    Maybe.unwrap
                        "[]"
                        (Result.unpack identity identity)
                        context.raw

                -- TODO: Remove backwards compatibility
                , sharedRepo = context.sharedRepo
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
    Return.singleton { model | reLinkApp = Flow.Failure err }


gotLinkAppParams : Suggest.Params -> Manager
gotLinkAppParams { cid, readKey, ucan } model =
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
                    [ ( "authorised", "via-postmessage" )
                    ]
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


gotLinkAppProgress : ProgressUpdate -> Manager
gotLinkAppProgress update model =
    case ( model.reLinkApp, Progress.fromString update.progress ) of
        ( InProgress progress, Just newProgress ) ->
            { progress = newProgress
            , progressTime = update.time
            , startTime = progress.startTime
            }
                |> InProgress
                |> (\flow -> { model | reLinkApp = flow })
                |> Return.singleton

        _ ->
            Return.singleton model
