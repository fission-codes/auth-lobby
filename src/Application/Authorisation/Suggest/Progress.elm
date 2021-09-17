module Authorisation.Suggest.Progress exposing (..)

-- 🌳


type Progress
    = Starting
    | Resolving
    | Loading
    | Identifying
    | Checking
    | Gathering
    | Encrypting
    | Storing
    | Updating


type alias TimedProgress =
    { progress : Progress
    , progressTime : Int
    , startTime : Int
    }


type alias ProgressUpdate =
    { time : Int
    , progress : String
    }


explain : Progress -> String
explain progress =
    case progress of
        Starting ->
            "Preparing UCANs"

        Resolving ->
            "Looking up data root"

        Loading ->
            "Loading your filesystem"

        Identifying ->
            "Ensuring .well-known public key"

        Checking ->
            "Checking existence of directories & files"

        Gathering ->
            "Gathering cryptography essentials"

        Encrypting ->
            "Encrypting classified data"

        Storing ->
            "Storing encrypted data"

        Updating ->
            "Updating data root"



-- 🛠


toString : Progress -> String
toString progress =
    case progress of
        Starting ->
            "Starting"

        Resolving ->
            "Resolving"

        Loading ->
            "Loading"

        Identifying ->
            "Identifying"

        Checking ->
            "Checking"

        Gathering ->
            "Gathering"

        Encrypting ->
            "Encrypting"

        Storing ->
            "Storing"

        Updating ->
            "Updating"


fromString : String -> Maybe Progress
fromString string =
    case string of
        "Starting" ->
            Just Starting

        "Resolving" ->
            Just Resolving

        "Loading" ->
            Just Loading

        "Identifying" ->
            Just Identifying

        "Checking" ->
            Just Checking

        "Gathering" ->
            Just Gathering

        "Encrypting" ->
            Just Encrypting

        "Storing" ->
            Just Storing

        "Updating" ->
            Just Updating

        _ ->
            Nothing
