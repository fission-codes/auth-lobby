module Share.State exposing (..)

import Json.Decode as Json
import Page
import Radix exposing (..)
import Return exposing (return)
import Share.Accept.Flow
import Share.Accept.Progress



-- 📣


accept : Manager
accept =
    Share.Accept.Flow.accept


gotAcceptShareError : String -> Manager
gotAcceptShareError error model =
    case model.page of
        Page.AcceptShare context ->
            error
                |> Share.Accept.Progress.Failed
                |> (\progress -> { context | progress = progress })
                |> Page.AcceptShare
                |> (\page -> { model | page = page })
                |> Return.singleton

        _ ->
            Return.singleton model


gotAcceptShareProgress : String -> Manager
gotAcceptShareProgress =
    Share.Accept.Flow.progress


listSharedItems : Json.Value -> Manager
listSharedItems =
    Share.Accept.Flow.listSharedItems
