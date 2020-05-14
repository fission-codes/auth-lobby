module View exposing (..)

import Html exposing (Html)
import Radix exposing (Model, Msg(..))
import Tailwind as T



-- 🖼


view : Model -> List (Html Msg)
view model =
    [ Html.div
        [ T.bg_gray_600
        , T.flex
        , T.font_body
        , T.h_screen
        , T.items_center
        , T.justify_center
        , T.w_screen
        ]
        [ if model.hasCreatedAccount then
            Html.text "Hello new user 👋"

          else
            Html.text "Linking new device 📱"
        ]
    ]
