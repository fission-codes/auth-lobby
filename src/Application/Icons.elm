module Icons exposing (..)

import FeatherIcons
import Html exposing (Html)


wrap : List (Html.Attribute msg) -> FeatherIcons.Icon -> Html msg
wrap attributes icon =
    Html.span attributes [ FeatherIcons.toHtml [] icon ]
