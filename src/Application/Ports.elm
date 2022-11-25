port module Ports exposing (..)

import Authorisation.Suggest.Params as Suggest
import Authorisation.Suggest.Progress exposing (ProgressUpdate)
import Json.Decode as Json



-- 📣


port checkIfUsernameIsAvailable : String -> Cmd msg


port copyToClipboard : String -> Cmd msg


port createAccount : { did : String, email : String, username : String } -> Cmd msg


port focusOnForm : () -> Cmd msg


port leave : () -> Cmd msg



-- 📣  ▒▒  LINKING


port confirmLinkAccountPin : () -> Cmd msg


port createAccountConsumer : String -> Cmd msg


port createAccountProducer : () -> Cmd msg


port destroyAccountProducer : () -> Cmd msg


port linkApp :
    { attenuation :
        List
            { capability : String
            , resource : ( String, String )
            }
    , canPermissionFiles : Bool
    , didWrite : String
    , didExchange : String
    , lifetimeInSeconds : Int
    , keyInSessionStorage : Bool
    , raw : String

    -- TODO: Remove backwards compatibility
    , sharedRepo : Bool
    , oldFlow : Bool
    }
    -> Cmd msg


port linkedDevice :
    { readKey : String
    , ucan : String
    , username : String
    }
    -> Cmd msg


port rejectLinkAccountPin : () -> Cmd msg



-- 📣  ▒▒  SHARING


port loadShare : { shareId : String, senderUsername : String } -> Cmd msg


port acceptShare : { sharedBy : String } -> Cmd msg



-- 📰


port gotCreateAccountFailure : (String -> msg) -> Sub msg


port gotCreateAccountSuccess : (() -> msg) -> Sub msg



-- 📰  ▒▒  LINKING


port gotLinkAccountCancellation : (() -> msg) -> Sub msg


port gotLinkAccountPin : (List Int -> msg) -> Sub msg


port gotLinkAccountSuccess : ({ username : String } -> msg) -> Sub msg


port gotLinkAppError : (String -> msg) -> Sub msg


port gotLinkAppParams : (Suggest.Params -> msg) -> Sub msg


port gotLinkAppProgress : (ProgressUpdate -> msg) -> Sub msg


port gotUsernameAvailability : ({ available : Bool, valid : Bool } -> msg) -> Sub msg



-- 📰  ▒▒  SHARING


port gotAcceptShareProgress : (String -> msg) -> Sub msg


port gotAcceptShareError : (String -> msg) -> Sub msg


port listSharedItems : (Json.Value -> msg) -> Sub msg
