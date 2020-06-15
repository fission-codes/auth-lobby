module Account.Linking.State exposing (..)

import Account.Linking.Context as Context exposing (Context)
import Page
import Radix exposing (..)
import Return exposing (return)



-- 📣


gotUsernameInput : String -> Manager
gotUsernameInput input =
    adjustContext
        (\c -> { c | username = input })



-- 🛠


adjustContext : (Context -> Context) -> Manager
adjustContext mapFn model =
    case model.page of
        Page.LinkAccount context ->
            Return.singleton { model | page = Page.LinkAccount (mapFn context) }

        _ ->
            Return.singleton model
