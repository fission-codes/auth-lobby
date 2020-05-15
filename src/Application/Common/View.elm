module Common.View exposing (..)

import FeatherIcons
import Html exposing (Html)


wrapIcon : List (Html.Attribute msg) -> FeatherIcons.Icon -> Html msg
wrapIcon attributes icon =
    Html.span attributes [ FeatherIcons.toHtml [] icon ]
