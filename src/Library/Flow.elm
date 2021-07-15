module Flow exposing (..)

-- 🧩


type Flow e i
    = NotStarted
    | InProgress i
    | Success
    | Failure e



-- 🛠


isFailure : Flow e i -> Bool
isFailure flow =
    case flow of
        Failure _ ->
            True

        _ ->
            False


isInProgress : Flow e i -> Bool
isInProgress flow =
    case flow of
        InProgress _ ->
            True

        _ ->
            False
