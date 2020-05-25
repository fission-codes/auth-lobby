module Authorisation.Suggest.View exposing (view)

import Branding
import External.Context exposing (defaultFailedState)
import Html exposing (Html)
import Loading
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Tailwind as T



-- 🖼


view : Model -> Html Msg
view model =
    case Debug.log "" model.externalContext of
        Failure _ ->
            External.Context.note model.externalContext

        Success _ ->
            Html.div
                []
                [ Branding.logo { usedUsername = model.usedUsername }
                ]

        _ ->
            { defaultFailedState | required = True }
                |> Failure
                |> External.Context.note
