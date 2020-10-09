module Common exposing (..)

import Browser.Dom as Dom
import Task
import Url exposing (Url)


focus : msg -> String -> Cmd msg
focus msg id =
    Task.attempt
        (\_ -> msg)
        (Dom.focus id)


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
