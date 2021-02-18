module Other.State exposing (..)

import Http
import Json.Decode as Decode
import Ports
import Radix exposing (Manager)
import RemoteData exposing (RemoteData(..))
import Return exposing (return)
import Theme
import Theme.Defaults



-- 📣


copyToClipboard : String -> Manager
copyToClipboard string model =
    string
        |> Ports.copyToClipboard
        |> return model


decodeTheme : String -> Manager
decodeTheme json model =
    json
        |> Decode.decodeString Theme.theme
        |> Result.mapError Decode.errorToString
        |> RemoteData.fromResult
        |> (\r -> { model | theme = r })
        |> Return.singleton


gotThemeViaHttp : Result Http.Error String -> Manager
gotThemeViaHttp result model =
    case result of
        Ok json ->
            decodeTheme json model

        Err _ ->
            Return.singleton { model | theme = NotAsked }


gotThemeViaIpfs : Result Http.Error String -> Manager
gotThemeViaIpfs =
    gotThemeViaHttp


leave : Manager
leave model =
    ()
        |> Ports.leave
        |> return model
