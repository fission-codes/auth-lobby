module View exposing (..)

import Html exposing (Html)
import Radix exposing (Model, Msg(..))
import Screens exposing (Screen(..))
import Tailwind as T



-- 🖼


view : Model -> List (Html Msg)
view model =
    [ Html.div
        [ T.bg_gray_600
        , T.flex
        , T.font_body
        , T.items_center
        , T.justify_center
        , T.min_h_screen
        , T.w_screen
        ]
        [ case model.screen of
            Choose ->
                Html.text "Hello person 👋 Create new account or sign in?"

            Create ->
                Html.text "Create new account 👩\u{200D}💻"

            Link ->
                Html.text "Linking new device 📱"
        ]
    ]
