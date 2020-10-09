module Account.Linking.Url exposing (..)

import Url.Parser.Query


screenParamsParser : Url.Parser.Query.Parser (Maybe String)
screenParamsParser =
    Url.Parser.Query.map2
        (\a b ->
            case ( a, b ) of
                ( Just n, Just u ) ->
                    if String.toLower n == "f" then
                        Just u

                    else
                        Nothing

                _ ->
                    Nothing
        )
        (Url.Parser.Query.string "newUser")
        (Url.Parser.Query.string "username")
