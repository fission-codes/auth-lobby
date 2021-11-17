module Share.Accept.Progress exposing (..)

-- 🌳


type Progress
    = Failed String
      --
    | Loading
    | Loaded (List { name : String, isFile : Bool })
    | Accepting
    | Publishing
    | Published



-- 🛠


fromString : String -> Maybe Progress
fromString string =
    case string of
        "Loading" ->
            Just Loading

        "Loaded" ->
            Just (Loaded [])

        "Accepting" ->
            Just Accepting

        "Publishing" ->
            Just Publishing

        "Published" ->
            Just Published

        _ ->
            Nothing


toString : Progress -> String
toString progress =
    case progress of
        Failed _ ->
            "Failed"

        Loading ->
            "Loading"

        Loaded _ ->
            "Loaded"

        Accepting ->
            "Accepting"

        Publishing ->
            "Publishing"

        Published ->
            "Published"
