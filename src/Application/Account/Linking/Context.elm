module Account.Linking.Context exposing (..)

import Account.Linking.Progress exposing (..)



-- 🧩


type alias Context =
    { note : Maybe String
    , progress : Maybe Progress
    , username : String
    , waitingForDevices : Bool
    }



-- 🌱


default : Context
default =
    { note = Nothing
    , progress = Nothing
    , username = ""
    , waitingForDevices = False
    }


initConsumerLink : Context
initConsumerLink =
    { default | progress = Just (Consumer WaitingOnProducer) }


initProducerLink : Context
initProducerLink =
    { default | progress = Just (Producer WaitingOnConsumer) }
