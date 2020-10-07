module Common exposing (..)

import Url exposing (Url)


ifThenElse : Bool -> a -> a -> a
ifThenElse condition x y =
    if condition then
        x

    else
        y


urlOrigin : Url -> String
urlOrigin url =
    url
        |> (\u -> { u | query = Nothing })
        |> Url.toString
        |> (\s ->
                if String.endsWith "/" s then
                    String.dropRight 1 s

                else
                    s
           )
