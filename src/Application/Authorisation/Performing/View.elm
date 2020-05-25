module Authorisation.Performing.View exposing (view)

import External.Context exposing (defaultFailedState)
import Html exposing (Html)
import Loading
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Tailwind as T



-- 🖼


view : Model -> Html Msg
view model =
    case model.externalContext of
        Failure _ ->
            External.Context.note model.externalContext

        Success _ ->
            [ Html.text "Just a moment, granting access." ]
                |> Html.div [ T.italic, T.mt_3 ]
                |> List.singleton
                |> Loading.screen

        _ ->
            { defaultFailedState | required = True }
                |> Failure
                |> External.Context.note
