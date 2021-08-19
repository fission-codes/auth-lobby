module Authorisation.Performing.View exposing (view)

import External.Context exposing (defaultFailedState)
import Html exposing (Html)
import Kit.Components as Kit
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Tailwind as T



-- 🖼


view : Model -> Html Msg
view model =
    Kit.loadingIndicator "Just a moment, granting access."
