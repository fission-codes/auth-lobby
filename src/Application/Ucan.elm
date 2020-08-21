module Ucan exposing (..)

import Common exposing (ifThenElse)



-- 🧩


type FilesystemPart
    = AppFolder String
    | PrivatePath String
    | PublicPath String



-- CONSTANTS


fsResourceKey =
    "floofs"


potency =
    { all = "*"
    , none = ""

    --
    , append = "APPEND"
    , destroy = "DESTROY"
    , update = "UPDATE"
    }



-- 🛠


fsResource : String -> FilesystemPart -> ( String, String )
fsResource host part =
    let
        path =
            case part of
                AppFolder p ->
                    "private/Apps/" ++ removeLeadingForwardSlash p

                PrivatePath p ->
                    "private/" ++ removeLeadingForwardSlash p

                PublicPath p ->
                    "public/" ++ removeLeadingForwardSlash p
    in
    path
        |> removeForwardSlashSuffix
        |> String.append "/"
        -- TODO: Waiting on API change
        --       |> String.append host
        |> Tuple.pair fsResourceKey



-- ㊙️


removeLeadingForwardSlash : String -> String
removeLeadingForwardSlash str =
    if String.startsWith "/" str then
        String.dropLeft 1 str

    else
        str


removeForwardSlashSuffix : String -> String
removeForwardSlashSuffix str =
    if String.endsWith "/" str then
        String.dropRight 1 str

    else
        str
