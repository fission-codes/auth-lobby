module Account.Common.State exposing (..)

import Account.Creation.Context as Context exposing (Context)
import Page
import Ports
import Radix exposing (..)
import RemoteData exposing (RemoteData(..))
import Return exposing (return)



-- 📣


afterAccountCreation : Context -> Manager
afterAccountCreation context model =
    Return.singleton
        { model
            | page =
                case model.externalContext of
                    NotAsked ->
                        Page.Choose

                    _ ->
                        Page.SuggestAuthorisation

            --
            , reCreateAccount = Success ()
            , usedUsername = Just context.username
        }
