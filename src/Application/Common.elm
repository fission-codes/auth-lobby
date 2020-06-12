module Common exposing (..)


ifThenElse : Bool -> a -> a -> a
ifThenElse condition x y =
    if condition then
        x

    else
        y
