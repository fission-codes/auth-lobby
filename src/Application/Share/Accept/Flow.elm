module Share.Accept.Flow exposing (..)

import Json.Decode as Json
import Page exposing (Page(..))
import Ports
import Radix exposing (Manager, Model, Msg)
import Return exposing (return)
import Share.Accept.Context exposing (Context)
import Share.Accept.Progress exposing (Progress(..))



-- 📣


accept : Manager
accept model =
    case model.page of
        Page.AcceptShare context ->
            ( model
            , Ports.acceptShare { sharedBy = context.sharedBy }
            )

        _ ->
            Return.singleton model


listSharedItems : Json.Value -> Manager
listSharedItems value model =
    case model.page of
        Page.AcceptShare context ->
            case Json.decodeValue sharedItemsDecoder value of
                Ok list ->
                    establishProgress context model (Loaded list)

                Err err ->
                    err
                        |> Json.errorToString
                        |> Failed
                        |> establishProgress context model

        _ ->
            Return.singleton model


progress : String -> Manager
progress string model =
    case ( model.page, Share.Accept.Progress.fromString string ) of
        ( Page.AcceptShare context, Just pro ) ->
            establishProgress context model pro

        _ ->
            Return.singleton model



-- 🔬


establishProgress : Context -> Model -> Progress -> ( Model, Cmd Msg )
establishProgress ctx model pro =
    Return.singleton { model | page = AcceptShare { ctx | progress = pro } }


sharedItemsDecoder : Json.Decoder (List { name : String, isFile : Bool })
sharedItemsDecoder =
    Json.list
        (Json.map2
            (\n i -> { name = n, isFile = i })
            (Json.field "name" Json.string)
            (Json.field "isFile" Json.bool)
        )
