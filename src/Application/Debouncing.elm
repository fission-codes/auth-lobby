module Debouncing exposing (..)

import Debouncer.Messages as Debouncer exposing (Debouncer, Milliseconds, fromSeconds)
import Radix exposing (..)
import Return



-- 🏔


ionDidValid =
    makeConfig
        { getter = .ionDidValidDebouncer
        , setter = \debouncer model -> { model | ionDidValidDebouncer = debouncer }

        --
        , msg = IonDidValidDebouncerMsg
        , settleAfter = fromSeconds 0.75
        }


usernameAvailability =
    makeConfig
        { getter = .usernameAvailabilityDebouncer
        , setter = \debouncer model -> { model | usernameAvailabilityDebouncer = debouncer }

        --
        , msg = UsernameAvailabilityDebouncerMsg
        , settleAfter = fromSeconds 0.75
        }



-- ⚗️


type alias Config model msg =
    { getter : model -> Debouncer msg
    , setter : Debouncer msg -> model -> model

    --
    , msg : Debouncer.Msg msg -> msg
    , settleAfter : Milliseconds
    }
    ->
        { debouncer : Debouncer msg
        , provideInput : msg -> msg
        , updateConfig : Debouncer.UpdateConfig msg model
        }


makeConfig : Config Model Msg
makeConfig { getter, msg, setter, settleAfter } =
    { debouncer =
        Debouncer.manual
            |> Debouncer.settleWhenQuietFor (Just settleAfter)
            |> Debouncer.toDebouncer

    --
    , provideInput =
        Debouncer.provideInput >> msg

    --
    , updateConfig =
        { mapMsg = msg
        , getDebouncer = getter
        , setDebouncer = setter
        }
    }
