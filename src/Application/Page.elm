module Page exposing (..)

import Account.Creation.Context as Creation
import Account.Linking.Context as Linking



-- 🧩


type Page
    = Choose
    | CreateAccount Creation.Context
    | LinkAccount Linking.Context
    | Note String
    | PerformingAuthorisation
    | SuggestAuthorisation
