module Page exposing (..)

import Account.Creation.Context as Creation



-- 🧩


type Page
    = Choose
    | CreateAccount Creation.Context
    | LinkAccount
    | LinkingApplication
