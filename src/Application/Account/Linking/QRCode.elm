module Account.Linking.QRCode exposing (..)

import Common
import Html exposing (Html)
import Html.Events as E
import QRCode
import Radix exposing (Msg)
import Svg.Attributes
import Tailwind as T
import Url exposing (Url)



-- 🖼


view : Url -> Maybe String -> Html Msg
view url maybeUsername =
    let
        urlWithParams =
            case maybeUsername of
                Just username ->
                    Common.urlOrigin url ++ "?newUser=f&username=" ++ Url.percentEncode username

                Nothing ->
                    Common.urlOrigin url
    in
    Html.div
        [ E.onClick (Radix.CopyToClipboard urlWithParams)

        --
        , T.border_2
        , T.border_dashed
        , T.border_base_300
        , T.cursor_pointer
        , T.inline_block
        , T.italic
        , T.mt_6
        , T.opacity_80
        , T.p_3
        , T.rounded_md
        , T.text_base_900

        -- Dark mode
        ------------
        , T.dark__border_base_600
        , T.dark__text_base_25
        ]
        [ urlWithParams
            |> QRCode.fromString
            |> Result.map
                (QRCode.toSvg
                    [ Svg.Attributes.width "90px"
                    , Svg.Attributes.height "90px"
                    , Svg.Attributes.stroke "currentColor"
                    ]
                )
            |> Result.withDefault
                (Html.text "Error while encoding to QRCode")
        ]
