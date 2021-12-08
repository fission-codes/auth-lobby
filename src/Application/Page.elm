module Page exposing (..)

import Account.Creation.Context as Creation
import Account.Linking.Context as Linking
import Share.Accept.Context as Share



-- 🧩


type Page
    = AcceptShare Share.Context
    | Choose
    | CreateAccount Creation.Context
    | LinkAccount Linking.Context
    | Note String
    | PerformingAuthorisation
    | SuggestAuthorisation
