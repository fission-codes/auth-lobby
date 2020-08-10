module List.Ext exposing (..)

{-| More `List` functions.
-}


{-| Flipped version of (::).

    >>> addTo [2, 3] 1
    [1, 2, 3]

-}
addTo : List a -> a -> List a
addTo list item =
    item :: list


{-| Flipped version of `append`.

    >>> prepend [2, 3] [1]
    [1, 2, 3]

-}
prepend : List a -> List a -> List a
prepend a b =
    List.append b a
