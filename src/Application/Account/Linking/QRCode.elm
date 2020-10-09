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


view : Url -> String -> Html Msg
view url username =
    let
        urlWithParams =
            Common.urlOrigin url
                ++ "?newUser=f&username="
                ++ Url.percentEncode username
    in
    Html.div
        [ E.onClick (Radix.CopyToClipboard urlWithParams)

        --
        , T.border_2
        , T.border_dashed
        , T.border_gray_500
        , T.cursor_pointer
        , T.inline_block
        , T.italic
        , T.mt_6
        , T.opacity_80
        , T.p_3
        , T.rounded_md
        , T.text_darkness

        -- Dark mode
        ------------
        , T.dark__border_gray_200
        , T.dark__text_gray_900
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
