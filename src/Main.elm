module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as A
import Tailwind as T



-- ⛩


type alias Flags =
    {}


type alias Model =
    {}


type alias Msg =
    ()


main : Program Flags Model Msg
main =
    Browser.document
        { init = \_ -> Tuple.pair {} Cmd.none
        , view = view
        , update = \_ _ -> Tuple.pair {} Cmd.none
        , subscriptions = \_ -> Sub.none
        }



-- 🖼


view : Model -> Browser.Document Msg
view _ =
    { title = "Fission"
    , body = body
    }


body : List (Html Msg)
body =
    [ Html.div
        [ T.bg_gray_600
        , T.flex
        , T.font_body
        , T.h_screen
        , T.items_center
        , T.justify_center
        , T.w_screen
        ]
        [ Html.text "Hello 👋" ]
    ]
